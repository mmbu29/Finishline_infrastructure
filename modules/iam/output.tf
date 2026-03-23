# --- EKS ---
output "eks_cluster_role_arn" {
  description = "The ARN of the EKS Cluster control plane role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "The ARN of the EKS Node Group role"
  value       = aws_iam_role.eks_nodes.arn
}


# --- Jumphost ---
output "jumphost_role_arn" {
  description = "CRITICAL: Used for EKS Access Entry mapping"
  value       = aws_iam_role.jumphost.arn
}

output "jumphost_role_name" {
  value = aws_iam_role.jumphost.name
}

output "jumphost_instance_profile_name" {
  description = "The name of the profile to be attached to the Jumphost EC2"
  value       = aws_iam_instance_profile.jumphost.name
}

# --- Aurora ---
output "aurora_s3_role_arn" {
  description = "The ARN of the role for Aurora S3 integration"
  value       = aws_iam_role.aurora_s3.arn
}
