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

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
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
  private_subnet_ids        = module.vpc.private_eks_subnet_ids
  cluster_service_role_arn  = module.iam.cluster_service_role_arn
  cluster_security_group_id = module.vpc.cluster_security_group_id
  environment               = var.environment
  ebs_csi_driver_role_arn   = module.iam.ebs_csi_driver_role_arn
  vpc_cni_role_arn          = module.iam.vpc_cni_role_arn
}

# Node Groups Module
module "nodegroups" {
  source = "../../modules/nodegroups"

  cluster_name           = var.cluster_name
  cluster_endpoint       = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = module.eks_cluster.cluster_ca_certificate
  private_subnet_ids     = module.vpc.private_eks_subnet_ids
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

# PRODUCTION MODULES - COMMENTED OUT FOR COST OPTIMIZATION
# Uncomment these for production environment later

# # Databases Module - EXPENSIVE ($400+/month)
# module "databases" {
#   vpc_cidr          = var.vpc_cidr
#   source = "../../modules/databases"
#
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   private_subnet_cidrs = module.vpc.private_subnet_cidrs
#   cluster_name       = var.cluster_name
#   environment        = var.environment
#   kms_key_id         = module.kms.key_arn
#   db_username        = var.db_username
# }

# # Storage Module - EFS EXPENSIVE ($45/month)
# module "storage" {
#   source = "../../modules/storage"
#
#   cluster_name = var.cluster_name
#   environment  = var.environment
#   kms_key_id   = module.kms.key_arn
# }

# # CloudFront Module - NOT NEEDED FOR DEV
# module "cloudfront" {
#   source = "../../modules/cloudfront"
#
#   cluster_name = var.cluster_name
#   alb_dns_name = module.eks_cluster.alb_dns_name
#   environment  = var.environment
# }

# # VPC Endpoints Module - EXPENSIVE
# module "vpc_endpoints" {
#   source = "../../modules/vpc-endpoints"
#
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   route_table_ids    = module.vpc.private_route_table_ids
#   security_group_id  = module.vpc.vpc_endpoint_security_group_id
# }

# # ElastiCache Module - EXPENSIVE ($37/month)
# module "elasticache" {
#   source = "../../modules/elasticache"
#
#   cluster_name       = var.cluster_name
#   vpc_id             = module.vpc.vpc_id
#   vpc_cidr           = var.vpc_cidr
#   private_subnet_ids = module.vpc.private_subnet_ids
#   private_subnet_cidrs = module.vpc.private_subnet_cidrs
# }

# COST-OPTIMIZED MODULES FOR DEVELOPMENT

# Single PostgreSQL Instance (replaces Aurora cluster)
resource "aws_db_instance" "postgres_dev" {
  identifier = "${var.cluster_name}-postgres-dev"
  
  instance_class = "db.t3.micro"  # $13/month
  engine         = "postgres"
  engine_version = "15.14"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "wasaadb"
  username = var.db_username
  password = random_password.postgres_dev.result
  
  vpc_security_group_ids = [aws_security_group.postgres_dev.id]
  db_subnet_group_name   = aws_db_subnet_group.dev.name
  
  backup_retention_period = 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name        = "${var.cluster_name}-postgres-dev"
    Environment = "development"
  }
}

resource "random_password" "postgres_dev" {
  length  = 16
  special = false
}

resource "aws_db_subnet_group" "dev" {
  name       = "${var.cluster_name}-dev-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids
  
  tags = {
    Name = "${var.cluster_name}-dev-subnet-group"
  }
}

resource "aws_security_group" "postgres_dev" {
  name_prefix = "${var.cluster_name}-postgres-dev-"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = {
    Name = "${var.cluster_name}-postgres-dev-sg"
  }
}

# Single Redis Instance (replaces cluster)
resource "aws_elasticache_subnet_group" "dev" {
  name       = "${var.cluster_name}-dev-cache-subnet"
  subnet_ids = module.vpc.private_subnet_ids
}

resource "aws_security_group" "redis_dev" {
  name_prefix = "${var.cluster_name}-redis-dev-"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = {
    Name = "${var.cluster_name}-redis-dev-sg"
  }
}

resource "aws_elasticache_replication_group" "dev" {
  replication_group_id = "${var.cluster_name}-redis-dev"
  description         = "Development Redis"
  
  node_type = "cache.t3.micro"  # $12/month
  port      = 6379
  
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled          = false
  
  subnet_group_name  = aws_elasticache_subnet_group.dev.name
  security_group_ids = [aws_security_group.redis_dev.id]
  
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  
  tags = {
    Name = "${var.cluster_name}-redis-dev"
  }
}

# MongoDB on EKS (replaces expensive DocumentDB)
resource "kubernetes_namespace" "mongodb" {
  metadata {
    name = "mongodb"
  }
  
  depends_on = [module.eks_cluster]
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb-secret"
    namespace = "mongodb"
  }
  
  data = {
    password = base64encode(random_password.mongodb.result)
  }
  
  depends_on = [kubernetes_namespace.mongodb]
}

resource "random_password" "mongodb" {
  length  = 16
  special = false
}

resource "kubernetes_persistent_volume_claim" "mongodb" {
  metadata {
    name      = "mongodb-pvc"
    namespace = "mongodb"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    storage_class_name = "gp3"
  }
  
  depends_on = [kubernetes_namespace.mongodb]
}

resource "kubernetes_deployment" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = "mongodb"
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        app = "mongodb"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }
      
      spec {
        container {
          name  = "mongodb"
          image = "mongo:7.0"
          
          port {
            container_port = 27017
          }
          
          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mongodb-secret"
                key  = "password"
              }
            }
          }
          
          volume_mount {
            name       = "mongodb-storage"
            mount_path = "/data/db"
          }
          
          resources {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }
        }
        
        volume {
          name = "mongodb-storage"
          persistent_volume_claim {
            claim_name = "mongodb-pvc"
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_secret.mongodb, kubernetes_persistent_volume_claim.mongodb]
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = "mongodb"
  }
  
  spec {
    selector = {
      app = "mongodb"
    }
    
    port {
      port        = 27017
      target_port = 27017
    }
    
    type = "ClusterIP"
  }
  
  depends_on = [kubernetes_deployment.mongodb]
}

# EBS Storage Class (replaces expensive EFS)
resource "kubernetes_storage_class" "ebs_gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }
  
  lifecycle {
    ignore_changes = all
  }
  
  depends_on = [module.eks_cluster]
}

# Alerts Module - creates SNS topics, Lambdas, EventBridge rules and alarms
module "alerts" {
  source = "../../modules/alerts"

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
 
# SSM Bastion Module
module "ssm_bastion" {
  source              = "../../modules/ssm-bastion"
  cluster_name        = var.cluster_name
  oidc_provider_arn   = module.eks_cluster.cluster_oidc_provider_arn
  oidc_provider       = "oidc.eks.${var.aws_region}.amazonaws.com/id/${module.eks_cluster.cluster_oidc_issuer_id}"
  aws_region          = var.aws_region
  tags                = { Environment = var.environment, Project = var.project_name, ManagedBy = "terraform" }
  kms_key_id          = module.kms.key_arn

  vpc_id              = module.vpc.vpc_id
  bastion_subnet_id   = module.vpc.private_subnet_ids[0]
  bastion_key_name    = "wasaa-eks-ssm-debug"
  bastion_ami_id      = "ami-0504602f6baa54f7c" # Amazon Linux 2 for af-south-1 (2025-10-08)
}

# ECR OIDC Module
module "ecr_oidc" {
  source            = "../../modules/ecr-oidc"
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks_cluster.cluster_oidc_provider_arn
  oidc_provider     = "oidc.eks.${var.aws_region}.amazonaws.com/id/${module.eks_cluster.cluster_oidc_issuer_id}"
  tags              = { Environment = var.environment, Project = var.project_name, ManagedBy = "terraform" }
}