variable "db_username" {
  description = "Database admin username for Aurora PostgreSQL and DocumentDB"
  type        = string
  default     = "wasaa_admin"
}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "wasaachat"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "wasaa-prod-eks"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}