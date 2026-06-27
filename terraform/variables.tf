variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 website bucket"
  type        = string
}