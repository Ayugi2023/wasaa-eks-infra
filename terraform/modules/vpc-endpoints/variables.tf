variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route table IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for VPC endpoints"
  type        = string
}