# ========= variables ==========

variable "region" {
  type = string
}

variable "profile" {
  type = string
}

variable "key_pair" {
  type = string
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ========= general configuration ==========

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_s3_bucket" "cache" {
  bucket = "runner-cache-1"

  tags = {
    Name  = "runners-cache-1"
    Group = "gitlab-runners"

    Terraform = "true"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.cache.id
  acl    = "private"
}

# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source = "cloudposse/tfstate-backend/aws"
  version     = "0.38.1"
  namespace  = "gitlab-runners-pasqal"
  stage      = "dev"
  name       = "terraform"
  attributes = ["state"]

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}
