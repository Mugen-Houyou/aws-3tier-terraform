# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.vpc.db_subnet_group_name
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security_groups.alb_security_group_id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security_groups.web_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.security_groups.database_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.security_groups.bastion_security_group_id
}

# Compute Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host"
  value       = module.compute.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.compute.bastion_public_ip
}

output "web_instance_ids" {
  description = "IDs of the web servers"
  value       = module.compute.web_instance_ids
}

output "web_private_ips" {
  description = "Private IPs of the web servers"
  value       = module.compute.web_private_ips
}

# Database Outputs
output "primary_db_instance_id" {
  description = "Primary RDS instance ID"
  value       = module.database.primary_db_instance_id
}

output "primary_db_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = module.database.primary_db_endpoint
}

output "replica_db_instance_id" {
  description = "Read replica RDS instance ID"
  value       = module.database.replica_db_instance_id
}

output "replica_db_endpoint" {
  description = "Read replica RDS instance endpoint"
  value       = module.database.replica_db_endpoint
}

output "db_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = module.database.secret_arn
}

output "secret_name" {
  description = "Name of the secret containing database credentials"
  value       = module.database.secret_name
}

# Legacy outputs for backward compatibility
output "db_endpoint" {
  description = "Primary RDS instance endpoint (legacy)"
  value       = module.database.primary_db_endpoint
}

output "db_secret_name" {
  description = "Name of the secret containing database credentials (legacy)"
  value       = module.database.secret_name
}

# Connection Information
output "connection_info" {
  description = "Connection information for the infrastructure"
  value = {
    bastion_ssh = "ssh -i ~/.ssh/aws-key ec2-user@${module.compute.bastion_public_ip}"
    web_servers = [
      for i, ip in module.compute.web_private_ips : 
      "ssh -i ~/.ssh/aws-key -o ProxyJump=ec2-user@${module.compute.bastion_public_ip} ec2-user@${ip}"
    ]
    primary_database = "mysql -h ${module.database.primary_db_endpoint} -P ${module.database.db_port} -u admin -p ${module.database.db_name}"
    replica_database = var.enable_read_replica ? "mysql -h ${module.database.replica_db_endpoint} -P ${module.database.db_port} -u admin -p ${module.database.db_name}" : "Read replica not enabled"
  }
}
