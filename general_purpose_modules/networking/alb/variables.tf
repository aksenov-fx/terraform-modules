# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_name" {
  description = "The name to use for this ALB"
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
}

variable "LB_http_port" {
  type        = number
}