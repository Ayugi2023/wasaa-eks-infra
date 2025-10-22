output "cluster_service_role_arn" {
  description = "EKS cluster service role ARN"
  value       = aws_iam_role.cluster_service_role.arn
}

output "node_role_arn" {
  description = "EKS node role ARN"
  value       = aws_iam_role.node_role.arn
}

output "node_instance_profile_name" {
  description = "Node instance profile name"
  value       = aws_iam_instance_profile.node_instance_profile.name
}

output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller role ARN"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "ebs_csi_driver_role_arn" {
  description = "EBS CSI driver role ARN"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "efs_csi_driver_role_arn" {
  description = "EFS CSI driver role ARN"
  value       = aws_iam_role.efs_csi_driver.arn
}

output "external_secrets_role_arn" {
  description = "External Secrets role ARN"
  value       = aws_iam_role.external_secrets.arn
}

output "prometheus_role_arn" {
  description = "Prometheus role ARN"
  value       = aws_iam_role.prometheus.arn
}

output "container_insights_role_arn" {
  description = "Container Insights role ARN"
  value       = aws_iam_role.container_insights.arn
}

output "kubecost_role_arn" {
  description = "Kubecost role ARN"
  value       = aws_iam_role.kubecost.arn
}