variable "ami_id" {
  type        = string
}

variable "instance_type" {
  type        = string
}

variable "vpc_name" {
  type        = string
}

variable "public_subnet_name" {
  type        = string
}

variable "http_port" {
  description = "Port to open for webserver"
  type        = number
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
}

variable "server_text" {
  description = "The text the web server should return"
  type        = string
}

variable "user_data" {
  description = "Base64 encoded init script for the instance"
  type        = string
}

variable "instance_name" {
  description = "Tags to set for the instance"
  type        = map(string)
  default     = {}
}

variable "custom_tags" {
  description = "Custom tags to set on the Instance"
  type        = map(string)
  default     = {}
}