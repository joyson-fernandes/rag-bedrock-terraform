# ---------------------------------------------------------------------------
# S3 Docs Bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "docs" {
  bucket        = "${var.project}-docs-${var.docs_bucket_suffix}"
  force_destroy = true

  tags = { Name = "${var.project}-docs" }
}

resource "aws_s3_bucket_versioning" "docs" {
  bucket = aws_s3_bucket.docs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "docs" {
  bucket                  = aws_s3_bucket.docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# DynamoDB Sessions Table
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "timestamp"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = { Name = "${var.project}-sessions" }
}

# ---------------------------------------------------------------------------
# IAM Role for Lambda
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.project}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ApplyGuardrail",
        ]
        Resource = "*"
      },
      {
        Sid    = "BedrockKB"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate",
          "bedrock:GetPrompt",
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:rds!*"
      },
      {
        Sid    = "S3Docs"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.docs.arn,
          "${aws_s3_bucket.docs.arn}/*",
        ]
      },
      {
        Sid    = "DynamoSessions"
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.sessions.arn
      },
      {
        Sid    = "KmsViaSvc"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "secretsmanager.${var.region}.amazonaws.com",
              "rds.${var.region}.amazonaws.com",
            ]
          }
        }
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Lambda: Ingest
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "ingest" {
  function_name = "${var.project}-ingest"
  filename      = "${path.root}/../ingest.zip"
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 300
  memory_size   = 1024
  role          = aws_iam_role.lambda.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      AURORA_SECRET_ARN  = var.aurora_secret_arn
      AURORA_ENDPOINT    = var.aurora_endpoint
      AURORA_DATABASE    = var.aurora_database_name
      DOCS_BUCKET        = aws_s3_bucket.docs.id
      BEDROCK_REGION     = var.region
      EMBEDDING_MODEL_ID = "amazon.titan-embed-text-v2:0"
      GENERATION_MODEL_ID = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
      LOG_LEVEL          = "INFO"
    }
  }

  tags = { Name = "${var.project}-ingest" }
}

# ---------------------------------------------------------------------------
# Lambda: Query
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "query" {
  function_name = "${var.project}-query"
  filename      = "${path.root}/../query.zip"
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 1024
  role          = aws_iam_role.lambda.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      AURORA_SECRET_ARN      = var.aurora_secret_arn
      AURORA_ENDPOINT        = var.aurora_endpoint
      AURORA_DATABASE        = var.aurora_database_name
      SESSIONS_TABLE         = aws_dynamodb_table.sessions.name
      DOCS_BUCKET            = aws_s3_bucket.docs.id
      BEDROCK_REGION         = var.region
      EMBEDDING_MODEL_ID     = "amazon.titan-embed-text-v2:0"
      GENERATION_MODEL_ID    = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
      KB_GENERATION_MODEL_ID = "anthropic.claude-3-7-sonnet-20250219-v1:0"
      GUARDRAIL_ID           = ""  # Set after creating Guardrail in Bedrock console
      GUARDRAIL_VERSION      = "1"
      PROMPT_ARN             = ""  # Set after creating Prompt in Bedrock console
      KNOWLEDGE_BASE_ID      = ""  # Set after creating KB in Bedrock console
      LOG_LEVEL              = "INFO"
    }
  }

  tags = { Name = "${var.project}-query" }
}

# ---------------------------------------------------------------------------
# S3 Event Notification → Ingest Lambda (docs/ prefix only)
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.docs.arn
}

resource "aws_s3_bucket_notification" "ingest_trigger" {
  bucket = aws_s3_bucket.docs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"  # Critical: never trigger on evals/ or other prefixes
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}
