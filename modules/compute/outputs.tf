output "bastion_instance_id" {
  description = "ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "web_instance_ids" {
  description = "IDs of the web servers"
  value       = aws_instance.web[*].id
}

output "web_private_ips" {
  description = "Private IPs of the web servers"
  value       = aws_instance.web[*].private_ip
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.main.key_name
}
