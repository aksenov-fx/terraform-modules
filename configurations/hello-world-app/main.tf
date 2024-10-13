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

# --- --- --- --- --- --- --- --- --- --- #

locals {
  vpc_name = "TF-VPC1"
}

# --- --- --- --- --- --- --- --- --- --- #

# Get ami_id
data "aws_ami" "ami" {
  most_recent = true
  owners = ["137112412989"] #Amazon
  filter {
    name = "name"
    values = ["al2023-ami-2023.5*"] #Amazon_Linux_2023
  }
}

# --- --- --- --- --- --- --- --- --- --- #

module "hello_world_app" {

  source = "../../configurations_modules/hello-world-app"

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
              http_port   = var.http_port
              server_text = var.server_text
  }))

  environment                      = var.environment

  instance_type                    = "t2.micro"
  min_size                         = 2
  max_size                         = 3
  enable_autoscaling               = false
  ami                              = data.aws_ami.ami.id
  
  http_port                        = var.http_port
  LB_http_port                     = var.LB_http_port
  enable_egress                    = var.enable_egress

  vpc_name = local.vpc_name
  private_subnet_name_prefix = "${local.vpc_name}-private"
  public_subnet_name_prefix = "${local.vpc_name}-public"
  
  custom_tags = {first_tag = "first_tag_value"}
  
}