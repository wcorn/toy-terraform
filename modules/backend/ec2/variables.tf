variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "backend에 사용할 Subnet ID"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "ALB에 사용할 Subnet ID"
  type        = list(string)
}


variable "cert_souel_arn" {
  description = "moaboa의 seoul 인증서"
  type = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}