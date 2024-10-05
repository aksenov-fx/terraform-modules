terraform {
  required_version = ">= 1.9.5, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get ami_id
data "aws_ami" "Amazon_Linux_2023" {
  most_recent = true
  owners = ["137112412989"]
  filter {
    name = "name"
    values = ["al2023-ami-2023.5*"]
  }
}

module "hello_world_app" {

  source = "../../configurations_modules/hello-world-app"

  server_text = var.server_text

  environment        = var.environment

  instance_type      = "t2.micro"
  min_size           = 2
  max_size           = 2
  enable_autoscaling = false
  ami                = data.aws_ami.Amazon_Linux_2023.id
  enable_egress      = var.enable_egress
  
}