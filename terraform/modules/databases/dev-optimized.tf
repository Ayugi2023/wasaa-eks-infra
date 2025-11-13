# Development-optimized database configuration
# Reduces costs by 70% while maintaining functionality

# Single PostgreSQL instance instead of Aurora cluster
resource "aws_db_instance" "postgres_dev" {
  identifier = "${var.cluster_name}-postgres-dev"
  
  # Use smaller instance for development
  instance_class = "db.t3.micro"  # $13/month vs $77/month for db.t3.medium
  
  engine         = "postgres"
  engine_version = "15.8"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "wasaadb"
  username = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string).username
  password = jsondecode(data.aws_secretsmanager_secret_version.db_credentials_version.secret_string).password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Reduce backup retention for dev
  backup_retention_period = 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  # Enable auto minor version updates
  auto_minor_version_upgrade = true
  
  tags = {
    Name        = "${var.cluster_name}-postgres-dev"
    Environment = "development"
    CostOptimized = "true"
  }
}

# Replace DocumentDB with MongoDB on EKS (free)
# This eliminates the $252/month DocumentDB cost entirely
resource "kubernetes_namespace" "mongodb" {
  metadata {
    name = "mongodb"
  }
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
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb-secret"
    namespace = "mongodb"
  }
  
  data = {
    password = base64encode(random_password.mongodb.result)
  }
}

resource "random_password" "mongodb" {
  length  = 16
  special = false
}
