# --- Provider / Authentication Variables ---
# These allow the Helm provider to talk to your specific cluster

variable "cluster_name" {
  description = "The name of the EKS cluster (e.g., finishline-dev-eks)"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

# --- Module Logic Variables ---

variable "vpc_id" {
  description = "VPC ID where the EKS cluster and ALB reside"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the Helm deployment"
  type        = string
  default     = "us-east-1"
}

variable "alb_controller_role_arn" {
  description = "The IAM Role ARN created in the EKS module that the controller pod will assume"
  type        = string
}

variable "alb_name" {
  description = "The name/prefix for the Load Balancer created by the Ingress"
  type        = string
  default     = "finishline"
}

# Add this to ensure your Helm chart version is managed
variable "chart_version" {
  description = "The version of the aws-load-balancer-controller helm chart"
  type        = string
  default     = "1.7.2" # Use the latest stable version
}
