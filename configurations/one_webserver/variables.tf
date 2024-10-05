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

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "server_text" {
  description = "The text the web server should return"
  default     = "Hello, World"
  type        = string
}

variable "ssh_keyname" {
  description = "Name of the key file"
  default     = "ssh_key"
  type        = string
}
