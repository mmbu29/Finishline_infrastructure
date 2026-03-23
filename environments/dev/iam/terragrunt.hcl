include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars          = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  # Define the ARN here locally to break the dependency cycle with the aurora module
  aurora_secret_arn = "arn:aws:secretsmanager:us-east-1:590183777783:secret:rds!cluster-94678625-5ea7-4929-aa84-9529c2eb0e44-P0z0rb"
}

terraform {
  source = "../../../modules/iam"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  account_id                 = local.env_vars.locals.account_id
  aws_region                 = local.env_vars.locals.aws_region
  environment                = local.env_vars.locals.environment
  
  # Pass the local ARN to the module input
  master_password_secret_arn = local.aurora_secret_arn
  
  # Pulling directly from your successful VPC apply
  vpc_id                     = dependency.vpc.outputs.vpc_id
  oidc_provider_arn          = dependency.vpc.outputs.oidc_provider_arn
  oidc_provider_url          = dependency.vpc.outputs.oidc_provider_url
  
  # Security group for later connectivity
  security_group_aurora      = dependency.vpc.outputs.security_group_aurora
}