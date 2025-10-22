variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_oidc_issuer_id" {
  description = "EKS cluster OIDC issuer ID"
  type        = string
}