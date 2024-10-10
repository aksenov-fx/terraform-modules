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

# --- --- --- --- --- --- --- --- --- --- #

locals {
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

# --- --- --- --- --- --- --- --- --- --- #

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

/* resource "aws_key_pair" "generated_key" {
  key_name   = "my-key-pair"
  public_key = file("../webserver.pub")
} */

resource "aws_key_pair" "generated_key" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# --- --- --- --- --- --- --- --- --- --- #

resource "aws_instance" "example" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"

  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]

  key_name               = aws_key_pair.generated_key.key_name

  user_data              = var.user_data

  user_data_replace_on_change = true

  tags = var.custom_tags

}

# --- --- --- --- --- --- --- --- --- --- #

resource "aws_security_group" "instance" {
  name = "example_security_group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "allow_8080" {
  type              = "ingress"
  from_port         = var.http_port
  to_port           = var.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
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
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = local.tcp_protocol
  security_group_id = aws_security_group.instance.id
  cidr_blocks       = local.all_ips
  description       = "Allow SSH traffic from all IPs"
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.instance.id
  cidr_blocks       = local.all_ips
  description       = "Allow all outbound traffic"
}