###############################################
# 0. Caller Identity (needed for KMS policy)
###############################################
data "aws_caller_identity" "current" {}

###############################################
# 1. KMS Key for EKS Encryption
###############################################
resource "aws_kms_key" "eks" {
  description         = "KMS key for EKS secrets encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEKSService"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEKSClusterRole"
        Effect = "Allow"
        Principal = {
          AWS = var.eks_cluster_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################
# 2. EKS Cluster Definition
###############################################
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.environment}-eks"
  role_arn = var.eks_cluster_role_arn
  version  = "1.31"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.home_cidrs
    security_group_ids      = [var.eks_cluster_sg_id]
  }

  # FIXED: Use the KMS key created in this module
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

###############################################
# 3. Managed Node Group
###############################################
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "bottlerocket-mng"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.private_subnet_ids
  ami_type        = "BOTTLEROCKET_x86_64"
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_eks_cluster.main]
}

###############################################
# 4. OIDC Provider (IRSA)
###############################################
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

###############################################
# 5. ALB Controller IAM
###############################################
data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.project}-${var.environment}-ALBControllerPolicy"
  description = "Permissions required by the AWS Load Balancer Controller"
  policy      = data.http.iam_policy.response_body
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.project}-${var.environment}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com",
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "aws_iam_role_policy_attachment" "alb_controller_managed" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

###############################################
# 6. EKS Access Entries (Jumphost)
###############################################
resource "aws_eks_access_entry" "jumphost" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.jumphost_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jumphost_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.jumphost_role_arn

  access_scope {
    type = "cluster"
  }
}
