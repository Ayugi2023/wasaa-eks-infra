output "s3_bucket_endpoint" {
  value = module.storage.s3_bucket_endpoint
}
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.vpc_cidr
}

output "cilium_operator_role_arn" {
  description = "Cilium Operator role ARN"
  value       = module.iam.cilium_operator_role_arn
}

output "aurora_postgres_endpoint" {
  value = module.databases.aurora_postgres_endpoint
}

output "aurora_postgres_reader_endpoint" {
  value = module.databases.aurora_postgres_reader_endpoint
}

output "s3_bucket_name" {
  value = module.storage.s3_bucket_name
}

output "node_role_arn" {
  description = "EKS node role ARN (can be used to verify SSM policy)"
  value       = module.iam.node_role_arn
}

output "node_instance_profile_name" {
  description = "Node instance profile name"
  value       = module.iam.node_instance_profile_name
}

output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "documentdb_endpoint" {
  value = module.databases.documentdb_endpoint
}

# ECR OIDC outputs
output "ecr_role_arn" {
  description = "ARN of the ECR OIDC IAM role"
  value       = module.ecr_oidc.ecr_role_arn
}

output "ecr_service_account_name" {
  description = "Name of the ECR service account"
  value       = module.ecr_oidc.service_account_name
}