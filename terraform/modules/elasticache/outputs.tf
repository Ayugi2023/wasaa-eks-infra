output "redis_endpoint" {
  value = aws_elasticache_replication_group.main.configuration_endpoint_address
}
