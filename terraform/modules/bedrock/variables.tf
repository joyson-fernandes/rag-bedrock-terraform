variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "docs_bucket_arn" {
  description = "ARN of the S3 docs bucket"
  type        = string
}

variable "docs_bucket_name" {
  description = "Name of the S3 docs bucket"
  type        = string
}

variable "aurora_cluster_arn" {
  description = "ARN of the Aurora cluster (for Knowledge Base RDS vector store)"
  type        = string
}

variable "aurora_secret_arn" {
  description = "Secrets Manager ARN for Aurora credentials"
  type        = string
}

variable "aurora_database_name" {
  description = "Aurora database name"
  type        = string
  default     = "ragdb"
}
