########################################
# Data Sources
########################################

data "aws_caller_identity" "current" {}

########################################
# VPC
########################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# Default Security Group (Locked Down)
########################################

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name        = "${var.environment}-default-sg"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# KMS Key for CloudWatch Logs
########################################

resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableAccountRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsUseOfTheKey"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-cloudwatch-kms"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# CloudWatch Log Group for VPC Flow Logs
########################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.environment}-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = {
    Name        = "${var.environment}-vpc-flow-logs"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# IAM Role for VPC Flow Logs
########################################

resource "aws_iam_role" "flow_logs" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-vpc-flow-logs-role"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# IAM Policy for Flow Logs
########################################

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

########################################
# VPC Flow Logs
########################################

resource "aws_flow_log" "vpc" {
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = {
    Name        = "${var.environment}-vpc-flow-logs"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# Public Subnets
########################################

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${each.key}"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
    Tier        = "public"

    "kubernetes.io/role/elb"                   = "1"
    "kubernetes.io/cluster/finishline-dev-eks" = "shared"
    "karpenter.sh/discovery"                   = "finishline-dev-eks"
  }
}

########################################
# Private Subnets
########################################

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name        = "${var.environment}-private-${each.key}"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
    Tier        = "private"

    "kubernetes.io/role/internal-elb"          = "1"
    "kubernetes.io/cluster/finishline-dev-eks" = "shared"
    "karpenter.sh/discovery"                   = "finishline-dev-eks"
  }
}

########################################
# NAT Gateway + EIP (Single for Dev)
########################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  # Uses the first public subnet found in the map
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[keys(var.public_subnets)[0]].id

  tags = {
    Name = "${var.environment}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

########################################
# Route Tables
########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

########################################
# Security Groups
########################################

resource "aws_security_group" "aurora" {
  name        = "${var.environment}-aurora-sg"
  description = "Aurora PostgreSQL SG"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-aurora-sg"
  }
}

resource "aws_security_group" "jumphost" {
  name        = "${var.environment}-jumphost-sg"
  description = "Jumphost SG"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-jumphost-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-eks-nodes-sg"
  }
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "EKS Cluster Control Plane Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-eks-cluster-sg"
  }
}

########################################
# Security Group Rules
########################################

resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other (Intra-Node)"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "jumphost_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.home_cidrs
  security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "alb_to_eks" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "eks_to_aurora" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "jumphost_to_aurora" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "nodes_to_cluster_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "cluster_to_nodes_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

########################################
# VPC Endpoints
########################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.environment}-s3-endpoint"
  }
}