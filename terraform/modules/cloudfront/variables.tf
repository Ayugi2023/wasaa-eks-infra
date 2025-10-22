variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}