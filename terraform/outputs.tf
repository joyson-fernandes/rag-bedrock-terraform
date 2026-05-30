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

# ---- Bedrock outputs — use these to update Query Lambda env vars ----

output "guardrail_id" {
  description = "Bedrock Guardrail ID — set as GUARDRAIL_ID on Query Lambda"
  value       = module.bedrock.guardrail_id
}

output "guardrail_version" {
  description = "Bedrock Guardrail published version"
  value       = module.bedrock.guardrail_version
}

output "prompt_arn" {
  description = "Versioned Prompt ARN — set as PROMPT_ARN on Query Lambda"
  value       = module.bedrock.prompt_arn
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID — set as KNOWLEDGE_BASE_ID on Query Lambda"
  value       = module.bedrock.knowledge_base_id
}

output "eval_role_arn" {
  description = "IAM role ARN for Bedrock Evaluations jobs"
  value       = module.bedrock.eval_role_arn
}
