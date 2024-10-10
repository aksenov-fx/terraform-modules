output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

output "private_key_pem" {
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}