
terraform {
  # Require any 1.x version of Terraform
  required_version = ">= 1.9.5, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# --- --- --- --- --- --- --- --- --- --- #

data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}"]
  }
}

data "aws_subnets" "vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

data "aws_subnet" "subnets" {
  for_each = toset(data.aws_subnets.vpc_subnets.ids)
  id       = each.value
}

locals {
  public_subnets = [
    for subnet in data.aws_subnet.subnets :
    subnet.id if can(subnet.tags["Name"]) && strcontains(lower(subnet.tags["Name"]), lower(var.public_subnet_name_prefix))
  ]

  # private_subnets = [
  #   for subnet in data.aws_subnet.subnets :
  #   subnet.id if can(subnet.tags["Name"]) && strcontains(lower(subnet.tags["Name"]), lower(var.private_subnet_name_prefix))
  # ]

}

# --- --- --- --- --- --- --- --- --- --- #

module "asg" {
  source = "git::https://github.com/aksenov-fx/terraform-modules.git//general_purpose_modules/asg-rolling-deploy"
  #source = "../../general_purpose_modules/asg-rolling-deploy"

  cluster_name       = "${basename(path.cwd)}-${var.environment}"
  ami                = var.ami
  instance_type      = var.instance_type

  user_data          = var.user_data

  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling

  vpc_id             = data.aws_vpc.existing_vpc.id
  subnet_ids         = local.public_subnets
  http_port          = var.http_port
  enable_egress      = var.enable_egress

  target_group_arns  = [aws_lb_target_group.asg.arn]
  health_check_type  = "ELB"
  
  custom_tags = var.custom_tags
}

# --- --- --- --- --- --- --- --- --- --- #

module "alb" {
  source = "git::https://github.com/aksenov-fx/terraform-modules.git//general_purpose_modules/networking/alb"
  #source = "../../general_purpose_modules/networking/alb"

  alb_name   = "hello-world-${var.environment}"

  vpc_id = data.aws_vpc.existing_vpc.id
  subnet_ids = local.public_subnets

  LB_http_port = 80
}

resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = module.alb.alb_http_listener_arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# --- --- --- --- --- --- --- --- --- --- #
