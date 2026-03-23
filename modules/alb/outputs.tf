# modules/alb/outputs.tf

/*
output "alb_arn" {
  description = "The ARN of the Load Balancer"
  value       = data.aws_lb.finishline.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer"
  value       = data.aws_lb.finishline.dns_name
}
*/

output "ingress_usage_guide" {
  description = "Required annotations for Kubernetes Ingress manifests"
  value       = <<EOF
To use the shared ALB with the required tagging and security:
metadata:
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: finishline
    alb.ingress.kubernetes.io/tags: group-tag=finishline
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
EOF
}
