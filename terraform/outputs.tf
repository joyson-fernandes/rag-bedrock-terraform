output "api_endpoint" {
  description = "API Gateway invoke URL"
  value       = module.api.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.api.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID (public client, no secret)"
  value       = module.api.client_id
}

output "aurora_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.database.cluster_endpoint
}

output "aurora_secret_arn" {
  description = "Secrets Manager ARN for Aurora credentials"
  value       = module.database.master_user_secret_arn
}

output "docs_bucket" {
  description = "S3 docs bucket name"
  value       = module.lambda.docs_bucket
}
