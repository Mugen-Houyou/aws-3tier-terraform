output "redis_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "redis_primary_endpoint" {
  description = "Primary endpoint for the Redis replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint for the Redis replication group"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_configuration_endpoint" {
  description = "Configuration endpoint for the Redis replication group"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "redis_member_clusters" {
  description = "List of member cluster IDs"
  value       = aws_elasticache_replication_group.redis.member_clusters
}

output "redis_auth_token_secret_arn" {
  description = "ARN of the secret containing Redis AUTH token"
  value       = var.auth_token_enabled ? aws_secretsmanager_secret.redis_auth_token[0].arn : null
}

output "redis_auth_token_secret_name" {
  description = "Name of the secret containing Redis AUTH token"
  value       = var.auth_token_enabled ? aws_secretsmanager_secret.redis_auth_token[0].name : null
}

output "redis_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.main.name
}

output "redis_parameter_group_name" {
  description = "Name of the ElastiCache parameter group"
  value       = aws_elasticache_parameter_group.redis.name
}
