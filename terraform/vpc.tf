locals {
  name = "net"
  azs  = ["${var.aws_region}a", "${var.aws_region}b"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = local.name
  cidr = "10.0.0.0/16"
  azs  = local.azs

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  database_subnets = ["10.0.5.0/24", "10.0.6.0/24"]

  public_subnet_names   = ["public-1a", "public-1b"]
  private_subnet_names  = ["app-1a", "app-1b"]
  database_subnet_names = ["data-1a", "data-1b"]

  create_database_subnet_route_table = true

  create_database_subnet_group = true
  database_subnet_group_name   = "data-subnets"

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}