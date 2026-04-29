########################################
# Identification & Tagging
########################################

variable "environment" {
  type        = string
  description = "Deployment environment (dev/prod)"
}

variable "project" {
  type        = string
  default     = "finishline"
}

########################################
# Network Configuration
########################################

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where EKS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets where nodes will live (Private)"
}

variable "eks_cluster_sg_id" {
  type        = string
  description = "Security group for the EKS control plane"
}

########################################
# Access & Security
########################################

variable "home_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the public endpoint"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}

########################################
# IAM & Roles
########################################

variable "eks_cluster_role_arn" {
  type        = string
  description = "ARN of the IAM role for the EKS cluster"
}

variable "eks_node_role_arn" {
  type        = string
  description = "ARN of the IAM role for the EKS node group"
}

variable "jumphost_role_arn" {
  type        = string
  description = "ARN of the Jumphost role for EKS Access Entry"
}