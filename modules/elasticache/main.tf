# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-subnet-group"
    Type = "Cache"
  })
}

# ElastiCache Parameter Group for Redis
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis8.x"
  name   = "${var.project_name}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-parameter-group"
  })
}

# ElastiCache Replication Group (Master-Slave)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id         = "webapp-redis-${var.environment}"
  description                  = "Redis cluster for ${var.project_name}"
  
  # Redis Configuration
  engine               = "redis"
  engine_version       = var.redis_version
  node_type           = var.node_type
  port                = var.redis_port
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  
  # Cluster Configuration
  num_cache_clusters = var.num_cache_nodes
  
  # Network Configuration
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.security_group_id]
  
  # Backup Configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window         = var.snapshot_window
  maintenance_window      = var.maintenance_window
  
  # Security
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                = var.auth_token_enabled ? random_password.redis_auth_token[0].result : null
  
  # Monitoring
  notification_topic_arn = var.notification_topic_arn
  
  # Multi-AZ
  multi_az_enabled = var.multi_az_enabled
  
  # Auto Failover (requires Multi-AZ)
  automatic_failover_enabled = var.automatic_failover_enabled && var.multi_az_enabled
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-cluster"
    Type = "Cache"
    Tier = "Cache"
  })

  depends_on = [
    aws_elasticache_subnet_group.main,
    aws_elasticache_parameter_group.redis
  ]
}

# Random password for Redis AUTH token (optional)
resource "random_password" "redis_auth_token" {
  count   = var.auth_token_enabled ? 1 : 0
  length  = 32
  special = true
}

# Store Redis AUTH token in AWS Secrets Manager (optional)
resource "aws_secretsmanager_secret" "redis_auth_token" {
  count                   = var.auth_token_enabled ? 1 : 0
  name                    = "${var.project_name}-redis-auth-token"
  description             = "Redis AUTH token for ${var.project_name}"
  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-redis-auth-token"
    Type = "Secret"
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  count     = var.auth_token_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.redis_auth_token[0].id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token[0].result
  })
}
