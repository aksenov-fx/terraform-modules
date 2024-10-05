terraform {
  required_version = ">= 1.9.5, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./webserver.pem"
}

/* resource "aws_key_pair" "generated_key" {
  key_name   = "my-key-pair"
  public_key = file("../webserver.pub")
} */

resource "aws_key_pair" "generated_key" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "example" {
  ami                    = "ami-037774efca2da0726"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.generated_key.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y httpd
              sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
              echo "Hello, World" | sudo tee /var/www/html/index.html
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = var.security_group_name
}

resource "aws_security_group_rule" "allow_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instance.id
}

/* resource "aws_security_group_rule" "allow_ssh_from_prefix_list" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.instance.id
  prefix_list_ids   = ["pl-03915406641cb1f53"]
  description       = "Allow SSH traffic from the specified prefix list"
} */

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.instance.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SSH traffic from the specified prefix list"
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.instance.id
  cidr_blocks       = ["0.0.0.0/0"]  # Allows access to any public address
  description       = "Allow all outbound traffic"
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}
