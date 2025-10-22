output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_token" {
  description = "EKS cluster authentication token"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}

output "alb_dns_name" {
  description = "ALB DNS name (placeholder)"
  value       = "placeholder-alb.us-west-2.elb.amazonaws.com"
}

output "cluster_oidc_issuer_id" {
  description = "EKS cluster OIDC issuer ID"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/", "")
}

data "aws_region" "current" {}