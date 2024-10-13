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
  #map_public_ip_on_launch = true

  tags = {
    Example = "example_tag"
  }

}

# --- --- --- --- --- --- --- --- --- --- #

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = module.vpc.vpc_id
#   service_name = "com.amazonaws.us-east-2.s3"  # S3 Endpoint for us-east-2

#   # Attach the VPC endpoint to the route tables of the private subnets
#   route_table_ids = module.vpc.private_route_table_ids

#   tags = {
#     Name = "s3-vpc-endpoint"
#   }
# }