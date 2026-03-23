output "jumphost_id" {
  description = "The ID of the jumphost instance"
  value       = aws_instance.main.id
}

output "jumphost_public_ip" {
  description = "The public IP address assigned to the jumphost"
  value       = aws_instance.main.public_ip
}

output "jumphost_private_ip" {
  description = "The private IP address of the jumphost"
  value       = aws_instance.main.private_ip
}

output "ssh_connection_string" {
  description = "Convenience string for connecting via SSH"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.main.public_ip}"
}
