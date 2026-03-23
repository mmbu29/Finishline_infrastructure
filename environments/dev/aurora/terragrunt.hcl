include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aurora"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

inputs = {
  cluster_identifier = "finishline-dev-aurora"
  database_name      = "finishlinedb"
  instance_class     = "db.t4g.medium"
  environment        = "dev"
  project            = "finishline"
  
  # Map the VPC outputs correctly
  vpc_id             = dependency.vpc.outputs.vpc_id

  kms_key_arn = "arn:aws:kms:us-east-1:590183777783:key/24427e06-54f2-4e49-bc2c-485c544f33b4"
  
  # CHANGE THIS: Use the private_subnet_ids output we saw in your VPC list
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids 
  
  # REMOVE OR COMMENT OUT: The old subnet_group_name line that was causing the error
  # subnet_group_name = dependency.vpc.outputs.database_subnet_group_name 

  security_group_ids = [dependency.vpc.outputs.security_group_aurora]
  iam_role_arn       = dependency.iam.outputs.aurora_s3_role_arn
}

