include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

terraform {
  source = "../../../modules/jumphost"
}

########################################
# Dependencies
########################################

dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

########################################
# Inputs
########################################

inputs = {
  environment = local.environment
  project     = "finishline"
  
  # Network - Pulling from VPC module outputs
  public_subnet_id  = dependency.vpc.outputs.public_subnet_ids[0]
  security_group_id = dependency.vpc.outputs.security_group_jumphost

  # Identity - Pulling from IAM module outputs
  instance_profile_name = dependency.iam.outputs.jumphost_instance_profile_name

  # Instance Configuration
  instance_type = "t3.micro"
  key_name      = "jenna" 
}