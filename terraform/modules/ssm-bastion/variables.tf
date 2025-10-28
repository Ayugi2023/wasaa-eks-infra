variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS cluster."
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL for EKS cluster (without ARN)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "KMS Key ID for CloudWatch log group encryption."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for bastion instance."
  type        = string
}

variable "bastion_ami_id" {
  description = "AMI ID for bastion EC2 instance."
  type        = string
}

variable "bastion_subnet_id" {
  description = "Subnet ID for bastion EC2 instance."
  type        = string
}

variable "bastion_key_name" {
  description = "Key pair name for bastion EC2 instance."
  type        = string
  default     = "wasaa-eks-ssm-debug"
}
