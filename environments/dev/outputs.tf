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
output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
}

output "db_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

output "db_secret_name" {
  description = "Name of the secret containing database credentials"
  value       = module.database.secret_name
}
