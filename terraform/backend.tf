# Update bucket and key to match your S3 state bucket
terraform {
  backend "s3" {
    bucket       = "YOUR-TERRAFORM-STATE-BUCKET"
    key          = "rag-bedrock/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true  # Native S3 locking (Terraform >= 1.9)
  }
}
