variable "environment" {
  description = "Environment name (e.g., dev)"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "cluster_identifier" {
  description = "The identifier for the Aurora cluster"
  type        = string
}

variable "database_name" {
  description = "The name of the initial database to create"
  type        = string
  default     = "finishline_db"
}

variable "instance_class" {
  description = "The instance type to use"
  type        = string
  default     = "db.t4g.medium"
}


variable "security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role for S3 integration"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key used to encrypt Aurora storage and Performance Insights"
}
