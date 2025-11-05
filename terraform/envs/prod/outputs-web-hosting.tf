# Web hosting outputs
output "web_hosting_s3_bucket" {
  description = "S3 bucket name for web hosting"
  value       = module.web_hosting.s3_bucket_name
}

output "web_hosting_cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = module.web_hosting.cloudfront_url
}

output "web_hosting_cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.web_hosting.cloudfront_distribution_id
  sensitive   = false
}

output "web_hosting_api_gateway_url" {
  description = "API Gateway URL for backend services"
  value       = module.web_hosting.api_gateway_url
}

output "web_hosting_deployment_info" {
  description = "Web hosting deployment information"
  value = {
    s3_bucket           = module.web_hosting.s3_bucket_name
    cloudfront_url      = module.web_hosting.cloudfront_url
    api_gateway_url     = module.web_hosting.api_gateway_url
    distribution_id     = module.web_hosting.cloudfront_distribution_id
  }
}
