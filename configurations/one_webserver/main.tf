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
data "aws_ami" "ami" {
  most_recent = true
  owners      = ["137112412989"] #Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-2023.5*"] #Amazon_Linux_2023
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

  ami_id        = data.aws_ami.ami.id
  instance_type = "t2.micro"

  vpc_name = "TF-VPC1"
  public_subnet_name = "TF-VPC1-public-us-east-2a"

  http_port   = var.http_port
  server_text = var.server_text

  ssh_port = var.ssh_port

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    http_port   = var.http_port
    server_text = var.server_text
  }))

  custom_tags = { 
    name = "${basename(path.cwd)}-${var.environment}"
    first_tag = "first_tag_value" 
  }

}

# --- --- --- --- --- --- --- --- --- --- #