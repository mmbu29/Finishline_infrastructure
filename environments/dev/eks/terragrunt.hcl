include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  # Standardized double-slash for Terragrunt module sourcing
  source = "../../../modules//eks" 
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-fake-id"
    private_subnet_ids = ["subnet-1", "subnet-2"]
    eks_cluster_sg_id  = "sg-cluster-fake"
  }
}

dependency "iam" {
  config_path = "../iam"

  mock_outputs = {
    eks_cluster_role_arn = "arn:aws:iam::590183777783:role/mock-cluster"
    eks_node_role_arn    = "arn:aws:iam::590183777783:role/mock-node"
    jumphost_role_arn    = "arn:aws:iam::590183777783:role/mock-jumphost"
  }
}

# Added to fetch the actual KMS Key ARN from your Aurora module
dependency "aurora" {
  config_path = "../aurora"

  mock_outputs = {
    aurora_kms_key_arn = "arn:aws:kms:us-east-1:590183777783:key/mock-key"
  }
}

inputs = {
  environment = local.env_vars.locals.environment
  project     = local.env_vars.locals.project

  # Your NJ Home IP
  home_cidrs  = ["74.88.51.116/32"]

  # FIX: Pulling the real ARN from aurora outputs to replace "your-key-uuid"
  kms_key_arn = dependency.aurora.outputs.aurora_kms_key_arn

  # Network Inputs
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  eks_cluster_sg_id  = dependency.vpc.outputs.eks_cluster_sg_id

  # IAM Inputs
  eks_cluster_role_arn = dependency.iam.outputs.eks_cluster_role_arn
  eks_node_role_arn    = dependency.iam.outputs.eks_node_role_arn
  jumphost_role_arn    = dependency.iam.outputs.jumphost_role_arn
  
  # Ensure the cluster is highly available internally
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
}