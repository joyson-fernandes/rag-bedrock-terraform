# ---------------------------------------------------------------------------
# Cognito User Pool
# ---------------------------------------------------------------------------
resource "aws_cognito_user_pool" "main" {
  name = "${var.project}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 12
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  tags = { Name = "${var.project}-user-pool" }
}

# Public app client — no client secret (required for USER_PASSWORD_AUTH from CLI)
resource "aws_cognito_user_pool_client" "cli" {
  name         = "${var.project}-cli"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false  # Public client — secret causes SECRET_HASH errors on CLI

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 60  # minutes
  refresh_token_validity = 30  # days
  token_validity_units {
    access_token  = "minutes"
    refresh_token = "days"
  }
}

# ---------------------------------------------------------------------------
# API Gateway HTTP API
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    allow_origins = ["*"]
  }

  tags = { Name = "${var.project}-api" }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# ---------------------------------------------------------------------------
# JWT Authorizer (Cognito)
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  name             = "cognito-jwt"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
    audience = [aws_cognito_user_pool_client.cli.id]
  }
}

# ---------------------------------------------------------------------------
# Integrations and Routes
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "query" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.query_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "ingest" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.ingest_function_arn
  payload_format_version = "2.0"
}

locals {
  routes = {
    "POST /query"    = { integration = aws_apigatewayv2_integration.query.id }
    "POST /query-kb" = { integration = aws_apigatewayv2_integration.query.id }
    "POST /ingest"   = { integration = aws_apigatewayv2_integration.ingest.id }
  }
}

resource "aws_apigatewayv2_route" "main" {
  for_each = local.routes

  api_id             = aws_apigatewayv2_api.main.id
  route_key          = each.key
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
  target             = "integrations/${each.value.integration}"
}

# ---------------------------------------------------------------------------
# Lambda permissions for API Gateway
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "query" {
  statement_id  = "AllowAPIGWQuery"
  action        = "lambda:InvokeFunction"
  function_name = var.query_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "ingest" {
  statement_id  = "AllowAPIGWIngest"
  action        = "lambda:InvokeFunction"
  function_name = var.ingest_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
