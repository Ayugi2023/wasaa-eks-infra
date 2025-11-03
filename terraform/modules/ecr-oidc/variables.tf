variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL without https://"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "wasaa_namespaces" {
  description = "List of wasaa namespaces to create service accounts in"
  type        = list(string)
  default = [
    "wasaa-admin-service",
    "wasaa-affiliate-service", 
    "wasaa-apps-service",
    "wasaa-audit-service",
    "wasaa-calls-service",
    "wasaa-chama-service",
    "wasaa-contact-service",
    "wasaa-developer-service",
    "wasaa-escrow-service",
    "wasaa-fundraiser-service",
    "wasaa-gateway-service",
    "wasaa-gift-service",
    "wasaa-groups-service",
    "wasaa-kafka-service",
    "wasaa-livestream-service",
    "wasaa-media-service",
    "wasaa-message-service",
    "wasaa-moderation-service",
    "wasaa-notification-service",
    "wasaa-shorts-service",
    "wasaa-status-service",
    "wasaa-storefront-service",
    "wasaa-support-service",
    "wasaa-user-service",
    "wasaa-wallet-service",
    "wasaa-web-service"
  ]
}
