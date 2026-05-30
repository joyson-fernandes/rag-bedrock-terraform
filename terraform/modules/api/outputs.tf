output "api_endpoint" {
  description = "API Gateway invoke URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "client_id" {
  description = "Cognito App Client ID (public client)"
  value       = aws_cognito_user_pool_client.cli.id
}

output "authorizer_id" {
  description = "JWT Authorizer ID"
  value       = aws_apigatewayv2_authorizer.cognito.id
}
