output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_arn" {
  description = "Aurora cluster ARN (required for Knowledge Base RDS vector store)"
  value       = aws_rds_cluster.main.arn
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for Aurora master user credentials"
  value       = aws_rds_cluster.main.master_user_secret[0].secret_arn
}
