variable "cluster_name" {
  description = "Short name of the cluster used in resource naming"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key id/arn to use for SNS topic encryption (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "critical_email_addresses" {
  description = "Email addresses that receive critical alerts"
  type        = list(string)
  default     = []
}

variable "warning_email_addresses" {
  description = "Email addresses that receive warning alerts"
  type        = list(string)
  default     = []
}

variable "slack_critical_webhook_url" {
  description = "Slack webhook URL for critical alerts (lambda will post here)"
  type        = string
  default     = ""
}

variable "slack_warning_webhook_url" {
  description = "Slack webhook URL for warning alerts (lambda will post here)"
  type        = string
  default     = ""
}

variable "slack_secret_arn" {
  description = "(Optional) ARN of the Secrets Manager secret that contains the Slack webhook URL. If provided, the lambda will read the secret at runtime instead of an env var. The secret can be a raw URL string or JSON {\"webhook\": \"https://...\"}."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC id used to scope VPC related EventBridge rules"
  type        = string
  default     = null
}

variable "rds_cluster_identifiers" {
  description = "List of RDS / Aurora cluster identifiers to create CPU and memory alarms for"
  type        = list(string)
  default     = []
}

variable "docdb_cluster_identifiers" {
  description = "List of DocumentDB cluster identifiers to create CPU and memory alarms for"
  type        = list(string)
  default     = []
}

variable "elasticache_cluster_ids" {
  description = "List of ElastiCache cluster ids (Redis) to create CPU/eviction alarms for"
  type        = list(string)
  default     = []
}

variable "alb_names" {
  description = "List of Application Load Balancer names (not ARN) to create RequestCount alarms for"
  type        = list(string)
  default     = []
}

variable "request_count_threshold" {
  description = "RequestCount threshold (sum over period) to trigger traffic alarm for ALBs"
  type        = number
  default     = 10000
}

variable "autoscaler_instance_threshold" {
  description = "Number of new cluster instances within the window to alert on (karpenter/autoscaler burst)"
  type        = number
  default     = 3
}

variable "autoscaler_window_minutes" {
  description = "Window in minutes to count new instances for the autoscaler burst detection"
  type        = number
  default     = 5
}
