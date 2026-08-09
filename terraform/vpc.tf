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
  create_database_subnet_group       = true
  database_subnet_group_name         = "data-subnets"

  enable_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "build_1a" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "ephem-build-1a"
  }
}

resource "aws_route_table" "build_rt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.vpc.igw_id
  }

  tags = {
    Name = "net-rt-build"
  }
}

resource "aws_route_table_association" "build_assoc" {
  subnet_id      = aws_subnet.build_1a.id
  route_table_id = aws_route_table.build_rt.id
}