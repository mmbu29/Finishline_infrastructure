resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  values = [yamlencode({
    clusterName = var.cluster_name
    vpcId       = var.vpc_id
    region      = var.aws_region
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        # This gives the Pod the IAM Role ARN from the EKS module
        "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
      }
    }
  })]
}
