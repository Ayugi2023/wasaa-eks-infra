# Development-optimized Redis configuration
# Reduces from 3-node cluster to single node

resource "aws_elasticache_replication_group" "dev_optimized" {
  replication_group_id = "${var.cluster_name}-redis-dev"
  description         = "Development Redis for ${var.cluster_name}"
  
  # Use smallest instance type
  node_type = "cache.t3.micro"  # $12/month vs $37/month for current setup
  port      = 6379
  
  # Single node for development (no clustering)
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled          = false
  
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]
  
  # Disable encryption for development (reduces cost)
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  
  # Shorter backup retention
  snapshot_retention_limit = 1
  snapshot_window         = "03:00-05:00"
  
  tags = {
    Name          = "${var.cluster_name}-redis-dev"
    Environment   = "development"
    CostOptimized = "true"
  }
}
