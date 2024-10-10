terraform {
  required_version = ">= 1.9.5, < 2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- --- --- --- --- --- --- --- --- --- #

data "aws_availability_zones" "available" {}

# --- --- --- --- --- --- --- --- --- --- #

locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = "10.1.0.0/16"
}

# --- --- --- --- --- --- --- --- --- --- #

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "TF-${basename(path.cwd)}"
  cidr = local.vpc_cidr

  azs             = local.azs

  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]

  public_subnets =  [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k+100)]
  map_public_ip_on_launch = true

  tags = {
    Example = "example_tag"
  }

}