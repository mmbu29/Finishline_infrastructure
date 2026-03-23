include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/jumphost"
}

# Dependencies ensure VPC and IAM are applied first
dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

inputs = {
  environment = "dev"
  project     = "finishline"
  
  # Network - Using the first public subnet for SSH access
  public_subnet_id  = dependency.vpc.outputs.public_subnet_ids[0]
  security_group_id = dependency.vpc.outputs.security_group_jumphost

  # This passes the profile containing the Secrets Manager permission
  instance_profile_name = dependency.iam.outputs.jumphost_instance_profile_name
  
  # Identity - Attaching the Instance Profile for SSM and AWS CLI
  instance_profile_name = dependency.iam.outputs.jumphost_instance_profile_name

  # Instance Config
  instance_type = "t3.micro"
  key_name      = "jenna" 
}