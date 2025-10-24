terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# KMS Module
module "kms" {
  source = "../../modules/kms"

  cluster_name = var.cluster_name
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  project_name = var.project_name
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  cluster_name           = var.cluster_name
  environment            = var.environment
  cluster_oidc_issuer_id = module.eks_cluster.cluster_oidc_issuer_id
}

# EKS Cluster Module
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_service_role_arn  = module.iam.cluster_service_role_arn
  cluster_security_group_id = module.vpc.cluster_security_group_id
  environment               = var.environment
  ebs_csi_driver_role_arn   = module.iam.ebs_csi_driver_role_arn
  efs_csi_driver_role_arn   = module.iam.efs_csi_driver_role_arn
  vpc_cni_role_arn          = module.iam.vpc_cni_role_arn
}

# Node Groups Module
module "nodegroups" {
  source = "../../modules/nodegroups"

  cluster_name           = var.cluster_name
  cluster_endpoint       = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = module.eks_cluster.cluster_ca_certificate
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_role_arn          = module.iam.node_role_arn
  environment            = var.environment
}

# Karpenter Module

# Add data source for AWS account ID
data "aws_caller_identity" "current" {}

module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name     = var.cluster_name
  cluster_endpoint = module.eks_cluster.cluster_endpoint
  node_role_arn    = module.iam.karpenter_node_role_arn
  environment      = var.environment
  aws_account_id   = data.aws_caller_identity.current.account_id
}

# Databases Module
module "databases" {
  source = "../../modules/databases"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_name       = var.cluster_name
  environment        = var.environment
  kms_key_id         = module.kms.key_arn
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  cluster_name = var.cluster_name
  environment  = var.environment
  kms_key_id   = module.kms.key_arn
}

# CloudFront Module
module "cloudfront" {
  source = "../../modules/cloudfront"

  cluster_name = var.cluster_name
  alb_dns_name = module.eks_cluster.alb_dns_name
  environment  = var.environment
}

# VPC Endpoints Module
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids
  security_group_id  = module.vpc.vpc_endpoint_security_group_id
}

# EFS Module
module "efs" {
  source = "../../modules/efs"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  kms_key_id         = module.kms.key_arn
}

# ElastiCache Module
module "elasticache" {
  source = "../../modules/elasticache"

  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}

# Observability Module
module "observability" {
  source = "../../modules/observability"

  cluster_name = var.cluster_name
}

# Alerts Module - creates SNS topics, Lambdas, EventBridge rules and alarms
module "alerts" {
  source = "../../../modules/alerts"

  cluster_name = var.cluster_name
  kms_key_id   = module.kms.key_arn
  tags         = { Environment = var.environment, Project = var.project_name, ManagedBy = "terraform" }

  critical_email_addresses = ["mikemurango00@gmail.com"]
  warning_email_addresses  = ["mike.murango@webmasters.co.ke"]

  slack_critical_webhook_url = ""
  slack_warning_webhook_url  = ""
  slack_secret_arn           = ""

  vpc_id = module.vpc.vpc_id

  rds_cluster_identifiers   = []
  docdb_cluster_identifiers = []
  elasticache_cluster_ids   = []
  alb_names                 = []

  request_count_threshold       = 20000
  autoscaler_instance_threshold = 3
  autoscaler_window_minutes     = 5
}