# variables.tf — Finishline VPC Module

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "finishline"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "home_cidrs" {
  description = "List of operator home IP CIDRs allowed to SSH into the jumphost."
  type        = list(string)
  # Tip: Ensure these are in CIDR notation, e.g., ["1.2.3.4/32"]
}

variable "public_subnets" {
  description = "Public subnets (ALB, NAT, Jumphost)."
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Private subnets (EKS, App, DB)."
  type = map(object({
    cidr = string
    az   = string
  }))
}

# REMOVED: variable "private_to_public_nat" 
# Since we are now using a single NAT Gateway, all private subnets 
# point to the same resource. This mapping is no longer required 
# in your main.tf logic.