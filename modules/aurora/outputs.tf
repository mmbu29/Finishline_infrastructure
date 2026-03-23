output "cluster_endpoint" {
  description = "The writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "The reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_identifier" {
  description = "The cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "database_name" {
  description = "The name of the database"
  value       = aws_rds_cluster.main.database_name
}

output "master_password_secret_arn" {
  description = "The ARN of the secret containing the master password"
  value       = aws_rds_cluster.main.master_user_secret[0].secret_arn
}

output "parameter_group_name" {
  description = "The name of the custom parameter group"
  value       = aws_db_parameter_group.finishline.name
}

output "aurora_kms_key_arn" {
  value = aws_kms_key.aurora.arn
}
