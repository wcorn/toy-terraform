# terraform provider 버전 지정
terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.91.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "peter-terraform-state-bn2gz7v3he1rj0ia"
    key  = "shared/terraform/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true
    dynamodb_table = "peter-terraform-state-bn2gz7v3he1rj0ia"
  }
} 

# AWS Provider
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source          = "../../modules/shared_vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  common_tags = var.common_tags
  env = var.env
}

module "openvpn" {
  source           = "../../modules/openvpn"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_a_id
  common_tags = var.common_tags
  env = var.env
}