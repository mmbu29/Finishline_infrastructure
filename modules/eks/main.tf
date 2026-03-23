# --- 1. EKS Cluster Definition ---
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.environment}-eks"
  role_arn = var.eks_cluster_role_arn
  version  = "1.31"

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.home_cidrs
    security_group_ids      = [var.eks_cluster_sg_id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }

  access_config {
    # Using API_AND_CONFIG_MAP allows us to use the new Access Entries
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

# --- 2. Managed Node Group ---
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

  depends_on = [aws_eks_cluster.main]
}

# --- 3. OIDC Provider (Crucial for IRSA) ---
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# --- 4. ALB Controller IAM Setup ---

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

# --- 5. EKS Access Entries (Jumphost Permissions) ---

# This creates the link between the Cluster and the Jumphost Role
resource "aws_eks_access_entry" "jumphost" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::590183777783:role/finishline-dev-jumphost-role"
  type          = "STANDARD"
}

# This grants the Jumphost Role 'ClusterAdmin' permissions
resource "aws_eks_access_policy_association" "jumphost_admin" {
  cluster_name = aws_eks_cluster.main.name
  # FIXED: Access policies use the 'eks' prefix, not 'iam'
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::590183777783:role/finishline-dev-jumphost-role"

  access_scope {
    type = "cluster"
  }
}
