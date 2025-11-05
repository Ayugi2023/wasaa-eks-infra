variable "bucket_name" {
  description = "Name of the S3 bucket for web hosting"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "eks_alb_dns_name" {
  description = "DNS name of the EKS Application Load Balancer"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
