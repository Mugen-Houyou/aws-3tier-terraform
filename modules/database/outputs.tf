output "primary_db_instance_id" {
  description = "Primary RDS instance ID"
  value       = aws_db_instance.primary.id
}

output "primary_db_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "replica_db_instance_id" {
  description = "Read replica RDS instance ID"
  value       = var.enable_read_replica ? aws_db_instance.read_replica[0].id : null
}

output "replica_db_endpoint" {
  description = "Read replica RDS instance endpoint"
  value       = var.enable_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.primary.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.primary.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.primary.username
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# Legacy outputs for backward compatibility
output "db_instance_id" {
  description = "Primary RDS instance ID (legacy)"
  value       = aws_db_instance.primary.id
}

output "db_endpoint" {
  description = "Primary RDS instance endpoint (legacy)"
  value       = aws_db_instance.primary.endpoint
}
