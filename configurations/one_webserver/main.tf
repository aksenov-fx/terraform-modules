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

# Get ami_id
data "aws_ami" "Amazon_Linux_2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.5*"]
  }
}

# --- --- --- --- --- --- --- --- --- --- #

resource "local_file" "private_key" {
  content  = module.one_webserver.private_key_pem
  filename = "./${var.ssh_keyname}.pem"
}

# --- --- --- --- --- --- --- --- --- --- #

module "one_webserver" {
  source = "../../configurations_modules/one_webserver"

  ami_id        = data.aws_ami.Amazon_Linux_2023.id
  instance_type = "t2.micro"

  http_port   = var.http_port
  server_text = var.server_text

  ssh_port = var.ssh_port

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    http_port   = var.http_port
    server_text = var.server_text
  }))

  #tags = {
  #  Name = "terraform-example"
  #}
}

# --- --- --- --- --- --- --- --- --- --- #
