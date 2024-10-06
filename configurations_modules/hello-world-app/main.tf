
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- --- --- --- --- --- --- --- --- --- #

module "asg" {
  source = "../../general_purpose_modules/asg-rolling-deploy"

  cluster_name  = "hello-world-${var.environment}"
  ami           = var.ami
  instance_type = var.instance_type

  user_data     = base64encode(templatefile("${path.module}/user-data.sh", {
    http_port   = var.http_port
    server_text = var.server_text
  }))

  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling

  subnet_ids        = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  
  custom_tags = var.custom_tags
}

# --- --- --- --- --- --- --- --- --- --- #

module "alb" {
  source = "../../general_purpose_modules/networking/alb"

  alb_name   = "hello-world-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

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
