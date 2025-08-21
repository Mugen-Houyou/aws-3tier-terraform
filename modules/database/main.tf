# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# AWS Secrets Manager secret for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials"
  description = "Database credentials for ${var.project_name}"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Primary RDS MySQL Instance (Master)
resource "aws_db_instance" "primary" {
  identifier = "webapp-database-primary"

  # Engine configuration
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false

  # Backup configuration (필수 - Read Replica를 위해)
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Monitoring and logging
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Performance Insights
  performance_insights_enabled = false

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = !var.deletion_protection

  # Single-AZ for primary (Read Replica는 별도 AZ에 배치)
  multi_az = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-database-primary"
    Tier = "Database"
    Role = "Primary"
  })
}

# Read Replica RDS Instance (Slave)
resource "aws_db_instance" "read_replica" {
  count = var.enable_read_replica ? 1 : 0

  identifier = "webapp-database-replica"

  # Read Replica configuration
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_replica_instance_class

  # Network configuration
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false

  # Monitoring and logging
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Performance Insights
  performance_insights_enabled = false

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = !var.deletion_protection

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-database-replica"
    Tier = "Database"
    Role = "ReadReplica"
  })

  depends_on = [aws_db_instance.primary]
}

# IAM role for RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
