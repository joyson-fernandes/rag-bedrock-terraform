output "ingest_function_arn" {
  value = aws_lambda_function.ingest.arn
}

output "ingest_function_name" {
  value = aws_lambda_function.ingest.function_name
}

output "query_function_arn" {
  value = aws_lambda_function.query.arn
}

output "query_function_name" {
  value = aws_lambda_function.query.function_name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}

output "docs_bucket" {
  value = aws_s3_bucket.docs.id
}

output "sessions_table" {
  value = aws_dynamodb_table.sessions.name
}
