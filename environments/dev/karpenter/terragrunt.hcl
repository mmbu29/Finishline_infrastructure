terraform {
  source = "../../../modules/karpenter-iam"
}

inputs = {
  cluster_name      = "finishline-dev-eks"
  oidc_provider_arn = "arn:aws:iam::590183777783:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/9AFCF1DED615BCC5B22B40191201B2A6"
  oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/9AFCF1DED615BCC5B22B40191201B2A6"
  
  # Add these two lines to handle the string logic here in HCL
  oidc_sub_key      = "oidc.eks.us-east-1.amazonaws.com/id/9AFCF1DED615BCC5B22B40191201B2A6:sub"
  oidc_aud_key      = "oidc.eks.us-east-1.amazonaws.com/id/9AFCF1DED615BCC5B22B40191201B2A6:aud"
}