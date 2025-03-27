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
    bucket         = "peter-terraform-state-bn2gz7v3he1rj0ia"
    key            = "dev/terraform/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "peter-terraform-state-bn2gz7v3he1rj0ia"
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source          = "../../modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  db_subnets      = var.db_subnets
  common_tags = var.common_tags
}

module "database" {
  source        = "../../modules/database"
  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.db_subnet_ids
  common_tags = var.common_tags
}

module "s3_fe" {
  source             = "../../modules/frontend/s3"
  fe_domain_name     = var.fe_domain_name
  domain_name_prefix = var.domain_name_prefix
  cert_us_arn        = module.route53.cert_us_arn
  common_tags = var.common_tags
}

module "pipeline_fe" {
  source    = "../../modules/frontend/pipeline"
  fe_bucket = module.s3_fe.fe_bucket
  common_tags = var.common_tags
}

module "route53" {
  source                = "../../modules/route53"
  domain_name_prefix    = var.domain_name_prefix
  domain_name           = var.domain_name
  fe_domain_name        = var.fe_domain_name
  fe_cdn_domain_name    = module.s3_fe.fe_cdn_domain_name
  fe_cdn_domain_zone_id = module.s3_fe.fe_cdn_domain_zone_id
  be_domain_name        = var.be_domain_name
  be_alb_dns_name       = module.backend.be_alb_dns_name
  be_alb_zone_id        = module.backend.be_alb_zone_id
  common_tags = var.common_tags
}

module "pipeline_be" {
  source               = "../../modules/backend/pipeline"
  backend_asg          = module.backend.backend_asg
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_instance_endpoint = module.database.db_instance_endpoint
  db_instance_username = module.database.db_instance_username
  db_instance_password = module.database.db_instance_password
  common_tags = var.common_tags
}

module "backend" {
  source             = "../../modules/backend/ec2"
  vpc_id             = module.vpc.vpc_id
  cert_souel_arn     = module.route53.cert_seoul_arn
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  common_tags        = var.common_tags
}
