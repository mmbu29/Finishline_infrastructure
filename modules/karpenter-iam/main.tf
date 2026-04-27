resource "aws_cloudformation_stack" "karpenter_iam" {
  name          = "karpenter-iam"
  template_body = file("${path.module}/karpenter-iam.yaml")

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    ClusterName      = var.cluster_name
    OIDCProviderArn  = var.oidc_provider_arn
    OIDCProviderUrl  = var.oidc_provider_url
  }
}
