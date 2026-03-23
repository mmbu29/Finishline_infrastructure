include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//alb"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-fake-id"
  }
}

dependency "eks" {
  config_path = "../eks"

  # Updated mock_outputs to include the role ARN now living in the EKS module
  mock_outputs = {
    cluster_name                       = "finishline-dev-eks"
    cluster_endpoint                   = "https://fake.eks.amazonaws.com"
    cluster_certificate_authority_data = "dGhpcy1pcy1hLWZha2UtY2VydA==" 
    alb_controller_role_arn            = "arn:aws:iam::590183777783:role/mock-alb-role"
  }
}

# We keep the IAM dependency if you have other general IAM outputs needed, 
# but the ALB Role is no longer here.
dependency "iam" {
  config_path = "../iam"
}

inputs = {
  # Environment metadata
  environment = local.env_vars.locals.environment
  project     = local.env_vars.locals.project
  aws_region  = local.env_vars.locals.aws_region

  # Infrastructure IDs from dependencies
  vpc_id       = dependency.vpc.outputs.vpc_id
  cluster_name = dependency.eks.outputs.cluster_name

  # FIXED: Pointing to the EKS dependency instead of IAM
  alb_controller_role_arn = dependency.eks.outputs.alb_controller_role_arn

  # Provider Authentication 
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data

  # Specific name for the data source lookup
  alb_name = "finishline-shared-alb"
}