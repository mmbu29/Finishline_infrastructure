# This tells Terragrunt to create a provider.tf file in every module it runs
# root.hcl

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
}

%{ if strcontains(path_relative_to_include(), "alb") }
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_certificate_authority_data != "" ? base64decode(var.cluster_certificate_authority_data) : ""
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  # Change block to argument with '='
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = var.cluster_certificate_authority_data != "" ? base64decode(var.cluster_certificate_authority_data) : ""
    # Change nested block to argument with '='
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}
%{ endif }
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "infra-project-mbu"
    key            = "${path_relative_to_include()}/network.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraformstatebucket2026"
  }
}