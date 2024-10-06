variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "http_port" {
  description = "Port to open for webserver"
  type        = number
  default     = 8080
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "server_text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello, world"
}

variable "ssh_keyname" {
  description = "Name of the key file"
  type        = string
  default     = "ssh_key"
}