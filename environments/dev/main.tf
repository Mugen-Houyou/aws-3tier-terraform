terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name           = var.project_name
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  common_tags           = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name      = var.project_name
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  common_tags      = local.common_tags
}

# Database Module
module "database" {
  source = "../../modules/database"

  project_name                = var.project_name
  db_subnet_group_name       = module.vpc.db_subnet_group_name
  database_security_group_id = module.security_groups.database_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_instance_class          = var.db_instance_class
  multi_az                   = var.db_multi_az
  deletion_protection        = var.db_deletion_protection
  common_tags                = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  project_name               = var.project_name
  instance_type              = var.instance_type
  public_key                 = var.public_key
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  bastion_security_group_id  = module.security_groups.bastion_security_group_id
  web_security_group_id      = module.security_groups.web_security_group_id
  db_endpoint                = module.database.db_endpoint
  common_tags                = local.common_tags

  depends_on = [module.database]
}
