output "public_ip" {
  value       = module.hello_world_app.alb_dns_name
  description = "The domain name of the load balancer"
}

output "LB_http_port" {
  value       = var.LB_http_port
}