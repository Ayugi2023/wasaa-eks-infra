variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cluster_service_role_arn" {
  description = "EKS cluster service role ARN"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Cluster security group ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ebs_csi_driver_role_arn" {
  description = "EBS CSI driver role ARN"
  type        = string
}

variable "efs_csi_driver_role_arn" {
  description = "EFS CSI driver role ARN"
  type        = string
}

variable "vpc_cni_role_arn" {
  description = "VPC CNI role ARN"
  type        = string
}