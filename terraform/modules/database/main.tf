# ---------------------------------------------------------------------------
# Aurora Serverless v2 PostgreSQL (pgvector)
# ---------------------------------------------------------------------------
resource "aws_rds_cluster" "main" {
  cluster_identifier = var.project
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "16.4"
  database_name      = "ragdb"

  # Credentials managed by Secrets Manager (auto-created and rotated)
  manage_master_user_password = true

  # Serverless v2 capacity
  serverlessv2_scaling_configuration {
    min_capacity = 0   # Scale-to-zero when idle
    max_capacity = 2
  }

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.aurora_security_group_id]
  storage_encrypted      = true
  # AWS-managed key — safer than CMK for dev (no PendingDeletion issues)

  # Enable Data API for RDS Query Editor in the AWS console
  enable_http_endpoint = true

  skip_final_snapshot = true

  tags = { Name = "${var.project}-cluster" }
}

resource "aws_rds_cluster_instance" "main" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = { Name = "${var.project}-instance" }
}

resource "aws_db_subnet_group" "main" {
  name       = var.project
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.project}-db-subnet-group" }
}

# ---------------------------------------------------------------------------
# NOTE: pgvector schema must be bootstrapped manually after cluster creation
# Run via RDS Query Editor in the AWS console:
#
#   CREATE EXTENSION IF NOT EXISTS vector;
#
#   CREATE TABLE IF NOT EXISTS source_files (
#     id          bigserial PRIMARY KEY,
#     s3_key      text NOT NULL UNIQUE,
#     ingested_at timestamptz DEFAULT now()
#   );
#
#   CREATE TABLE IF NOT EXISTS documents (
#     id          bigserial PRIMARY KEY,
#     source      text NOT NULL,
#     chunk_index integer NOT NULL,
#     content     text NOT NULL,
#     embedding   vector(1024),
#     metadata    jsonb,
#     created_at  timestamptz DEFAULT now(),
#     UNIQUE(source, chunk_index)
#   );
#
#   CREATE INDEX IF NOT EXISTS documents_embedding_idx
#     ON documents
#     USING hnsw (embedding vector_cosine_ops)
#     WITH (m = 16, ef_construction = 64);
# ---------------------------------------------------------------------------
