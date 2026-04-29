environment = "dev"
home_cidrs  = ["69.124.74.252/32"]

vpc_cidr = "10.0.0.0/16"

public_subnets = {
  "public-1a" = {
    cidr = "10.0.1.0/24"
    az   = "us-east-1a"
  }
  # NEW: Added second public subnet for ALB High Availability
  "public-1b" = {
    cidr = "10.0.2.0/24"
    az   = "us-east-1b"
  }
}



private_subnets = {
  private-1a = {
    cidr = "10.0.11.0/24"
    az   = "us-east-1a"
  }
  private-1b = {
    cidr = "10.0.21.0/24"
    az   = "us-east-1b"
  }
}

private_to_public_nat = {
  private-1a = "public-1a"
  private-1b = "public-1a"
}

aws_region = "us-east-1"
