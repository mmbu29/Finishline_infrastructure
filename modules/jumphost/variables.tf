variable "instance_profile_name" {
  description = "The name of the IAM instance profile for SSM and logging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_id" {
  description = "The public subnet ID to launch the jumphost in"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the jumphost"
  type        = string
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
  default     = "jenna"
}
