output "karpenter_controller_role_arn" {
  value = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterControllerRoleArn"]
}

output "karpenter_node_role_name" {
  value = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterNodeRoleName"]
}

output "karpenter_node_instance_profile_name" {
  value = aws_cloudformation_stack.karpenter_iam.outputs["KarpenterNodeInstanceProfileName"]
}
