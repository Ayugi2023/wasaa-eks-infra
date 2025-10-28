output "private_subnet_cidrs" {
  description = "CIDR blocks of EKS private subnets"
  value       = aws_subnet.private_eks[*].cidr_block
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for RDS"
  value       = aws_subnet.private[*].id
}

output "private_eks_subnet_ids" {
  description = "Private EKS subnet IDs"
  value       = aws_subnet.private_eks[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = aws_security_group.cluster.id
}

output "vpc_endpoint_security_group_id" {
  description = "VPC endpoint security group ID"
  value       = aws_security_group.vpc_endpoint.id
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = aws_route_table.private[*].id
}