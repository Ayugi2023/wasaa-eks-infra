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
  
  cluster_name                = var.cluster_name
  cluster_version            = var.cluster_version
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  cluster_service_role_arn   = module.iam.cluster_service_role_arn
  cluster_security_group_id  = module.vpc.cluster_security_group_id
  environment               = var.environment
  ebs_csi_driver_role_arn   = module.iam.ebs_csi_driver_role_arn
  efs_csi_driver_role_arn   = module.iam.efs_csi_driver_role_arn
}

# Node Groups Module
module "nodegroups" {
  source = "../../modules/nodegroups"
  
  cluster_name           = var.cluster_name
  cluster_endpoint       = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = module.eks_cluster.cluster_ca_certificate
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_role_arn         = module.iam.node_role_arn
  environment           = var.environment
}

# Karpenter Module
module "karpenter" {
  source = "../../modules/karpenter"
  
  cluster_name    = var.cluster_name
  cluster_endpoint = module.eks_cluster.cluster_endpoint
  node_role_arn   = module.iam.node_role_arn
  environment     = var.environment
}

# Databases Module
module "databases" {
  source = "../../modules/databases"
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_name       = var.cluster_name
  environment        = var.environment
  kms_key_id         = module.kms.key_id
}

# Storage Module
module "storage" {
  source = "../../modules/storage"
  
  cluster_name = var.cluster_name
  environment  = var.environment
  kms_key_id   = module.kms.key_id
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
  kms_key_id         = module.kms.key_id
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