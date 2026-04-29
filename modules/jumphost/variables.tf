########################################
# Identification & Tagging
########################################

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "finishline"
}

########################################
# Compute Configuration
########################################

variable "instance_type" {
  description = "EC2 instance type for the jumphost"
  type        = string
  default     = "t3.micro" # Sufficient for administrative tooling
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
  default     = "jenna"
}

########################################
# Networking & Security
########################################

variable "public_subnet_id" {
  description = "The public subnet ID where the jumphost will reside"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group allowing SSH/Management traffic"
  type        = string
}

variable "instance_profile_name" {
  description = "The name of the IAM instance profile providing SSM and EKS/Secrets permissions"
  type        = string
}