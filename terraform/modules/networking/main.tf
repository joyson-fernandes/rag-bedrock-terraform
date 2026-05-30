# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

# ---------------------------------------------------------------------------
# Private subnets (no public subnets — no IGW, no NAT Gateway)
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project}-private-${var.azs[count.index]}" }
}

# ---------------------------------------------------------------------------
# Route table (explicit — required for gateway endpoints)
# ---------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# Security Group: Lambda
# ---------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "${var.project}-lambda-sg"
  description = "Lambda functions — outbound to Aurora and VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Aurora (pgvector)
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Aurora PostgreSQL within VPC"
  }

  # Interface endpoints (Bedrock, Secrets Manager, CloudWatch)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS to VPC interface endpoints"
  }

  # Gateway endpoints (S3, DynamoDB use public IP ranges via route table)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for S3 and DynamoDB gateway endpoints"
  }

  tags = { Name = "${var.project}-lambda-sg" }
}

# ---------------------------------------------------------------------------
# Security Group: Aurora
# ---------------------------------------------------------------------------
resource "aws_security_group" "aurora" {
  name        = "${var.project}-aurora-sg"
  description = "Aurora — allow PostgreSQL only from Lambda SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "PostgreSQL from Lambda SG only"
  }

  tags = { Name = "${var.project}-aurora-sg" }
}

# ---------------------------------------------------------------------------
# Security Group: VPC Endpoints
# ---------------------------------------------------------------------------
resource "aws_security_group" "endpoints" {
  name        = "${var.project}-endpoints-sg"
  description = "VPC interface endpoints — HTTPS from VPC CIDR"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "HTTPS from VPC"
  }

  tags = { Name = "${var.project}-endpoints-sg" }
}

# ---------------------------------------------------------------------------
# Gateway Endpoints (free — route-table based)
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = { Name = "${var.project}-s3-endpoint" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = { Name = "${var.project}-dynamodb-endpoint" }
}

# ---------------------------------------------------------------------------
# Interface Endpoints (billable ~£0.008/hr/AZ each)
# ---------------------------------------------------------------------------
locals {
  interface_endpoints = [
    "bedrock-runtime",      # InvokeModel (embeddings + generation)
    "bedrock-agent",        # GetPrompt (Prompt Management)
    "bedrock-agent-runtime",# RetrieveAndGenerate (Knowledge Bases)
    "secretsmanager",       # GetSecretValue (Aurora credentials)
    "logs",                 # CloudWatch log delivery
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-${each.key}-endpoint" }
}
