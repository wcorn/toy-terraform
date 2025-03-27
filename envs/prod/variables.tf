variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "리스트 형태의 public subnet 정보"
  type = list(object({
    cidr                    = string
    az                      = string
    map_public_ip_on_launch = bool
  }))
  default = [
    {
      cidr                    = "10.20.10.0/24"
      az                      = "ap-northeast-2a"
      map_public_ip_on_launch = true
    },
    {
      cidr                    = "10.20.20.0/24"
      az                      = "ap-northeast-2c"
      map_public_ip_on_launch = true
    }
  ]
}

variable "private_subnets" {
  description = "리스트 형태의 private subnet 정보"
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    {
      cidr = "10.20.110.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "10.20.120.0/24"
      az   = "ap-northeast-2c"
    }
  ]
}

variable "db_subnets" {
  description = "리스트 형태의 DB용 private subnet 정보"
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    {
      cidr = "10.20.210.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "10.20.220.0/24"
      az   = "ap-northeast-2c"
    }
  ]
}

variable "domain_name_prefix" {
  description = "moaboa 도메인 이름 prefix"
  type        = string
  default     = "*.boamoa.shop"
}
variable "domain_name" {
  description = "moaboa 도메인 이름"
  type        = string
  default     = "boamoa.shop"
}
variable "fe_domain_name" {
  description = "frontend 도메인 이름"
  type        = string
  default     = "front.boamoa.shop"
}
variable "be_domain_name" {
  description = "backend 도메인 이름"
  type        = string
  default     = "back.boamoa.shop"
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "prod"
    Owner       = "peter"
  }
}

variable "env" {
  description = "환경"
  type        = string
  default = "prod"
}
