locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  environment = local.environment
  vpc_cidr    = "10.0.0.0/16"
  project     = "finishline"
  # Add your home IP if needed for the jumphost variable in your module
  home_cidrs  = ["69.124.74.252/32"] 

  public_subnets = {
    "public-1a" = { az = "us-east-1a", cidr = "10.0.1.0/24" }
    "public-1b" = { az = "us-east-1b", cidr = "10.0.2.0/24" }
  }

  private_subnets = {
    "private-1a" = { az = "us-east-1a", cidr = "10.0.11.0/24" }
    "private-1b" = { az = "us-east-1b", cidr = "10.0.21.0/24" }
  }

  # High Availability: Each private subnet gets its own NAT Gateway in its own AZ
  private_to_public_nat = {
    "private-1a" = "public-1a"
    "private-1b" = "public-1b"
  }
}