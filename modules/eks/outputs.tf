# --- Cluster Identity ---
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# --- Node Group Info ---
output "node_group_name" {
  description = "The name of the managed node group"
  value       = aws_eks_node_group.main.node_group_name
}

# --- IAM & IRSA (Identity Roles for Service Accounts) ---
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The full URL of the OIDC Provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "alb_controller_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}
