variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
  default     = "prod"
}
