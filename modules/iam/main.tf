locals {
  name = "finishline-${var.environment}"
}

########################################
# EKS Cluster Role
########################################

resource "aws_iam_role" "eks_cluster" {
  name = "${local.name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = { 
    Name        = "${local.name}-eks-cluster-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ])
  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

########################################
# EKS Node Group Role
########################################

resource "aws_iam_role" "eks_nodes" {
  name = "${local.name}-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { 
    Name        = "${local.name}-eks-nodes-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

########################################
# Jumphost Role & Instance Profile
########################################

resource "aws_iam_role" "jumphost" {
  name = "${local.name}-jumphost-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.name}-jumphost-role" }
}

resource "aws_iam_role_policy_attachment" "jumphost_ssm" {
  role       = aws_iam_role.jumphost.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jumphost" {
  name = "${local.name}-jumphost-profile"
  role = aws_iam_role.jumphost.name
}

########################################
# Aurora RDS Service Role (S3 Integration)
########################################

resource "aws_iam_role" "aurora_s3" {
  name = "${local.name}-aurora-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "rds.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.name}-aurora-s3-role" }
}

resource "aws_iam_role_policy" "aurora_s3_access" {
  name = "aurora-s3-access-policy"
  role = aws_iam_role.aurora_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::infra-project-mbu"]
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::infra-project-mbu/*"]
      }
    ]
  })
}

########################################
# Jumphost Scoped Access Policies
########################################

resource "aws_iam_policy" "jumphost_secrets" {
  name        = "${var.environment}-jumphost-secrets-policy"
  description = "Allows jumphost to retrieve database credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = "${var.master_password_secret_arn}*"
      },
      {
        Action   = "kms:Decrypt"
        Effect   = "Allow"
        Resource = "arn:aws:kms:us-east-1:590183777783:key/a09c4653-6034-4f72-be57-8d1918927e15"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jumphost_secrets_attach" {
  role       = aws_iam_role.jumphost.name
  policy_arn = aws_iam_policy.jumphost_secrets.arn
}

resource "aws_iam_policy" "jumphost_eks_describe" {
  name        = "${local.name}-jumphost-eks-policy"
  description = "Allows jumphost to discover and authenticate with EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:AccessKubernetesApi"
        ]
        Resource = "arn:aws:eks:us-east-1:590183777783:cluster/finishline-dev-eks*"
      },
      {
        Effect   = "Allow"
        Action   = ["eks:ListClusters"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jumphost_eks_attach" {
  role       = aws_iam_role.jumphost.name
  policy_arn = aws_iam_policy.jumphost_eks_describe.arn
}