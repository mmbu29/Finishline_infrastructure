variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
  default     = "finishline"
}

variable "aws_region" {
  description = "AWS Region (used for Aurora and Jumphost policy ARNs)"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID (12-digit number)"
  type        = string
  validation {
    condition     = can(regex("^\\d{12}$", var.account_id))
    error_message = "The account_id must be a 12-digit number."
  }
}

# --- New Variable for Scoped Policies ---
variable "vpc_id" {
  description = "The VPC ID where EKS and Aurora reside"
  type        = string
}

# ------------------------------------------------------------
# EKS / OIDC Variables
# ------------------------------------------------------------

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider (from EKS module) used for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "The URL of the OIDC Provider (from EKS module) used for IRSA"
  type        = string
}

variable "master_password_secret_arn" {
  description = "ARN of the Aurora master password secret"
  type        = string
}
