output "aurora_postgres_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "aurora_postgres_reader_endpoint" {
  value = aws_rds_cluster.main.reader_endpoint
}

# Uncomment and use if you have DocumentDB
output "documentdb_endpoint" {
  value = aws_docdb_cluster.main.endpoint
}
