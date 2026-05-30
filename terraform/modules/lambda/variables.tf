variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "lambda_security_group_id" {
  type = string
}

variable "docs_bucket_suffix" {
  type        = string
  description = "Suffix for S3 bucket name (use AWS account ID for uniqueness)"
  default     = "demo123"
}

variable "aurora_secret_arn" {
  type = string
}

variable "aurora_endpoint" {
  type = string
}

variable "aurora_database_name" {
  type = string
}
