locals {
  vpc_name            = "runners-vpc"
  vpc_cidr            = "10.0.0.0/16"
  vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  vpc_public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}

# ========= resources ==========

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.19.0"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.vpc_private_subnets
  public_subnets  = local.vpc_public_subnets

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = local.vpc_name
    Group     = "gitlab-runners"
    Terraform = "true"
  }

}
