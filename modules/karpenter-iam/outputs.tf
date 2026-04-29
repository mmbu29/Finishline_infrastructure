output "karpenter_controller_role_arn" {
  description = "The ARN of the Karpenter Controller IAM Role"
  value       = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterControllerRoleArn"]
}

output "karpenter_node_role_name" {
  description = "The name of the Karpenter Node IAM Role"
  value       = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterNodeRoleName"]
}

output "karpenter_node_instance_profile_name" {
  description = "The name of the Karpenter Node Instance Profile"
  value       = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterNodeInstanceProfileName"]
}