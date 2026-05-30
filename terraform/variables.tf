variable "region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "project" {
  description = "Project name prefix for all resources"
  default     = "rag-bedrock"
}

variable "azs" {
  description = "Availability zones"
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "docs_bucket_suffix" {
  description = "Suffix for the S3 docs bucket (use your AWS account ID for uniqueness)"
  default     = "demo123"
}
