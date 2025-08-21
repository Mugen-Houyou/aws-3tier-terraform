variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  type        = string
}

variable "web_security_group_id" {
  description = "Security group ID for web servers"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
