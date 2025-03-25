variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
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
      cidr                    = "192.168.10.0/24"
      az                      = "ap-northeast-2a"
      map_public_ip_on_launch = true
    },
    {
      cidr                    = "192.168.20.0/24"
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
      cidr = "192.168.210.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "192.168.220.0/24"
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
      cidr = "192.168.110.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "192.168.120.0/24"
      az   = "ap-northeast-2c"
    }
  ]
}

variable "domain_name_prefix" {
  description = "moaboa 도메인 이름 prefix"
  type        = string
  default     = "*.moaboa.shop"
}
variable "domain_name" {
  description = "moaboa 도메인 이름"
  type        = string
  default     = "moaboa.shop"
}

variable "fe_domain_name" {
  description = "frontend 도메인 이름"
  type        = string
  default     = "front.moaboa.shop"
}

variable "be_domain_name" {
  description = "backend 도메인 이름"
  type        = string
  default     = "backend.moaboa.shop"
}