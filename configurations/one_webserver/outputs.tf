output "public_ip" {
  value       = module.one_webserver.public_ip
  description = "The public IP address of the web server"
}

output "http_port" {
  value       = var.http_port
}