# ECR OIDC Integration Module
# This module creates IAM roles and policies for EKS pods to pull ECR images without secrets

data "aws_caller_identity" "current" {}

# IAM Role for ECR access via OIDC
resource "aws_iam_role" "ecr_oidc_role" {
  name = "${var.cluster_name}-ecr-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider, "https://", "")}:sub" = "system:serviceaccount:*:ecr-service-account"
          }
        }
      }
    ]
  })

  lifecycle {
    ignore_changes = all
  }

  tags = var.tags
}

# IAM Policy for ECR access
resource "aws_iam_policy" "ecr_policy" {
  name        = "${var.cluster_name}-ecr-policy"
  description = "Policy for ECR access from EKS pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/*",
          "arn:aws:ecr:af-south-1:${data.aws_caller_identity.current.account_id}:repository/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ecr_oidc_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

# Kubernetes Service Account for ECR access
resource "kubernetes_service_account" "ecr_service_account" {
  metadata {
    name      = "ecr-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ecr_oidc_role.arn
    }
  }
}

# Create service accounts in all wasaa namespaces
resource "kubernetes_service_account" "wasaa_ecr_service_accounts" {
  for_each = toset(var.wasaa_namespaces)
  
  metadata {
    name      = "ecr-service-account"
    namespace = each.value
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ecr_oidc_role.arn
    }
  }
}
