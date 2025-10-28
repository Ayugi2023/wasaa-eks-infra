variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for EKS private subnets in the VPC."
  type        = list(string)
}

variable "private_rds_subnet_cidrs" {
  description = "List of CIDR blocks for RDS private subnets in the VPC."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "db_username" {
  description = "Database admin username for Aurora PostgreSQL and DocumentDB. Store in AWS Secrets Manager for production."
  type        = string
}
