output "ecr_role_arn" {
  description = "ARN of the ECR OIDC IAM role"
  value       = aws_iam_role.ecr_oidc_role.arn
}

output "ecr_policy_arn" {
  description = "ARN of the ECR policy"
  value       = aws_iam_policy.ecr_policy.arn
}

output "service_account_name" {
  description = "Name of the ECR service account"
  value       = kubernetes_service_account.ecr_service_account.metadata[0].name
}
