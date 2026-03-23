output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_gateway_ids" {
  value = [for n in aws_nat_gateway.nat : n.id]
}

output "route_table_public_id" {
  value = aws_route_table.public.id
}

output "route_table_private_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}

output "security_group_alb" {
  value = aws_security_group.alb.id
}

output "security_group_eks_nodes" {
  value = aws_security_group.eks_nodes.id
}

output "security_group_aurora" {
  value = aws_security_group.aurora.id
}

output "security_group_jumphost" {
  value = aws_security_group.jumphost.id
}

output "oidc_provider_arn" {
  description = "Temporary mock ARN"
  value       = "arn:aws:iam::590183777783:oidc-provider/pending-eks-deployment"
}

output "oidc_provider_url" {
  description = "Temporary mock URL"
  value       = "https://oidc.eks.us-east-1.amazonaws.com/id/pending"
}

output "eks_cluster_sg_id" {
  description = "The ID of the EKS Cluster Security Group"
  value       = aws_security_group.eks_cluster.id
}
