output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.web_hosting.bucket
}

output "s3_bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.web_hosting.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.web_hosting.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.web_hosting.domain_name
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.web_hosting.domain_name}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.web_api.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.web_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.api_stage_name}"
}

output "api_gateway_invoke_url" {
  description = "Invoke URL of the API Gateway"
  value       = aws_api_gateway_deployment.web_api.invoke_url
}

data "aws_region" "current" {}
