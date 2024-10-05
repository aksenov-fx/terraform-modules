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
  region = var.aws_region
}

# --- --- --- --- --- --- --- --- --- --- #

locals {
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

# --- --- --- --- --- --- --- --- --- --- #

# Get ami_id
data "aws_ami" "Amazon_Linux_2023" {
  most_recent = true
  owners = ["137112412989"]
  filter {
    name = "name"
    values = ["al2023-ami-2023.5*"]
  }
}

# --- --- --- --- --- --- --- --- --- --- #

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./${var.ssh_keyname}.pem"
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
  ami                    = data.aws_ami.Amazon_Linux_2023.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.generated_key.key_name

  user_data              = base64encode(templatefile("${path.module}/user-data.sh", {
                           http_port = var.http_port
                           server_text = var.server_text
  }))

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

# --- --- --- --- --- --- --- --- --- --- #

resource "aws_security_group" "instance" {
  name = "example_security_group"
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