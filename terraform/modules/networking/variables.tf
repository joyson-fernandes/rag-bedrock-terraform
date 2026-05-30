variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}
