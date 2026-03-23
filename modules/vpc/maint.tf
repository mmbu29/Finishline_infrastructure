

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
  retention_in_days = 400
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

# tfsec:ignore:aws-iam-no-policy-wildcards
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

    # REQUIRED: Tells the controller these are for External ALBs
    "kubernetes.io/role/elb" = "1"
    # REQUIRED: Links subnets to your specific EKS Cluster
    "kubernetes.io/cluster/finishline-dev-eks" = "shared"
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

    # REQUIRED: Tells the controller these are for Internal ALBs
    "kubernetes.io/role/internal-elb" = "1"
    # REQUIRED: Links subnets to your specific EKS Cluster
    "kubernetes.io/cluster/finishline-dev-eks" = "shared"
  }
}

########################################
# NAT Gateway + EIP
########################################

resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip-${each.key}"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name        = "${var.environment}-nat-gw-${each.key}"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
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
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[var.private_to_public_nat[each.key]].id
  }

  tags = {
    Name        = "${var.environment}-private-rt-${each.key}"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

########################################
# Security Groups (Egress Only)
########################################

resource "aws_security_group" "aurora" {
  name        = "${var.environment}-aurora-sg"
  description = "Aurora PostgreSQL SG"
  vpc_id      = aws_vpc.main.id

  # checkov:skip=CKV2_AWS_5: "Attached in the RDS module"
  # checkov:skip=CKV_AWS_382: "Egress required for AWS API access"

  egress {
    description = "Outbound required for patches and AWS API access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-aurora-sg"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "jumphost" {
  name        = "${var.environment}-jumphost-sg"
  description = "Jumphost SG"
  vpc_id      = aws_vpc.main.id

  # checkov:skip=CKV2_AWS_5: "Attached to EC2 instance"
  # checkov:skip=CKV_AWS_382: "Required for updates"

  egress {
    description = "Outbound required for updates and SSM"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-jumphost-sg"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.main.id

  # checkov:skip=CKV2_AWS_5: "Attached to ALB resource"
  # checkov:skip=CKV_AWS_382: "Health checks egress"

  egress {
    description = "Outbound required for ALB health checks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-eks-nodes-sg"
  description = "EKS worker nodes SG"
  vpc_id      = aws_vpc.main.id

  # checkov:skip=CKV2_AWS_5: "Attached to EKS Node Group"
  # checkov:skip=CKV_AWS_382: "Nodes must pull images"

  egress {
    description = "Outbound required for pulling container images"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-eks-nodes-sg"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

########################################
# Security Group Rules (Ingress)
########################################

resource "aws_security_group_rule" "alb_http_in" {
  # checkov:skip=CKV_AWS_260: "Port 80 required for HTTP to HTTPS redirect"
  description = "Allow HTTP from internet"
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_https_in" {
  description = "Allow HTTPS from internet"
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "jumphost_ssh" {
  # checkov:skip=CKV_AWS_24: "SSH restricted to operator home IPs"
  description       = "SSH from home IP"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.home_cidrs
  security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "alb_to_eks" {
  description              = "Allow ALB to reach EKS nodes"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "eks_to_aurora" {
  description              = "Allow EKS nodes to reach Aurora"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "jumphost_to_aurora" {
  description              = "Allow Jumphost to Aurora"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora.id
  source_security_group_id = aws_security_group.jumphost.id
}


# VPC Endpoint for S3 (Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically associates with all private route tables
  route_table_ids = [for rt in aws_route_table.private : rt.id]

  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "EKS Cluster Control Plane Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Jumphost to communicate with the EKS API"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.jumphost.id]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow all outbound traffic for EKS API and AWS service communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-eks-cluster-sg"
  }
}

resource "aws_security_group_rule" "nodes_to_cluster_api" {
  description              = "Allow EKS nodes to communicate with the cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "cluster_to_nodes_kubelet" {
  description              = "Allow cluster control plane to talk to node kubelet"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}
