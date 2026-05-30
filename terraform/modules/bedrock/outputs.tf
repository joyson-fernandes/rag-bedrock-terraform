output "guardrail_id" {
  description = "Bedrock Guardrail ID — set as GUARDRAIL_ID env var on Query Lambda"
  value       = aws_bedrock_guardrail.main.guardrail_id
}

output "guardrail_arn" {
  description = "Bedrock Guardrail ARN"
  value       = aws_bedrock_guardrail.main.guardrail_arn
}

output "guardrail_version" {
  description = "Published Guardrail version"
  value       = aws_bedrock_guardrail_version.v1.version
}

output "prompt_arn" {
  description = "Versioned Prompt ARN — set as PROMPT_ARN env var on Query Lambda"
  value       = aws_bedrock_prompt_version.v1.prompt_arn
}

output "prompt_version" {
  description = "Published Prompt version"
  value       = aws_bedrock_prompt_version.v1.version
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID — set as KNOWLEDGE_BASE_ID env var on Query Lambda"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = aws_bedrockagent_knowledge_base.main.arn
}

output "data_source_id" {
  description = "Knowledge Base S3 data source ID"
  value       = aws_bedrockagent_data_source.docs.data_source_id
}

output "eval_role_arn" {
  description = "IAM role ARN for Bedrock Evaluations jobs"
  value       = aws_iam_role.eval.arn
}
