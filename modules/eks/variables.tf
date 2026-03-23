variable "environment" {
  type        = string
  description = "Deployment environment (dev/prod)"
}

variable "project" {
  type    = string
  default = "finishline-dev"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Subnets where nodes will live (Private)"
}

variable "eks_cluster_role_arn" {
  type = string
}

variable "eks_node_role_arn" {
  type = string
}

variable "jumphost_role_arn" {
  type = string
}

variable "eks_cluster_sg_id" {
  type        = string
  description = "Security group for the EKS control plane"
}

variable "home_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the public endpoint"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN for EKS secret encryption"
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = false
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}
