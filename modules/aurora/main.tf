# 1. Custom Parameter Group
resource "aws_db_parameter_group" "finishline" {
  name   = "finishline-parameter-group"
  family = "aurora-postgresql15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = { Name = "finishline-parameters" }
}

# 2. Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.cluster_identifier}-subnet-group" }
}

# 3. Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier          = var.cluster_identifier
  engine                      = "aurora-postgresql"
  engine_version              = "15.15"
  database_name               = var.database_name
  master_username             = "marcellus"
  manage_master_user_password = true
  kms_key_id                  = aws_kms_key.aurora.arn


  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  # iam_roles              = [var.iam_role_arn]

  # FIX #1 (HIGH): Enable Storage Encryption
  storage_encrypted = true

  # FIX #2 (MEDIUM): Set Backup Retention (7 days is standard for dev)
  backup_retention_period = 7

  skip_final_snapshot = true
}

# 4. Single Instance
resource "aws_rds_cluster_instance" "main" {
  count                           = 1
  identifier                      = "${var.cluster_identifier}-1"
  cluster_identifier              = aws_rds_cluster.main.id
  instance_class                  = var.instance_class
  engine                          = aws_rds_cluster.main.engine
  engine_version                  = aws_rds_cluster.main.engine_version
  db_parameter_group_name         = aws_db_parameter_group.finishline.name
  publicly_accessible             = false
  performance_insights_kms_key_id = aws_kms_key.aurora.arn


  # FIX #3 (LOW): Enable Performance Insights
  performance_insights_enabled = true
}

# NEW RESOURCE: Associate the IAM Role with the S3 feature
resource "aws_rds_cluster_role_association" "s3_import" {
  db_cluster_identifier = aws_rds_cluster.main.id
  role_arn              = var.iam_role_arn
  # FIX: Change to camelCase for PostgreSQL
  feature_name = "s3Import"
}

resource "aws_kms_key" "aurora" {
  description             = "KMS key for Aurora cluster and Performance Insights"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "finishline-aurora-kms"
  }
}
