variable "domain_name_prefix" {
  description = "도메인 이름 prefix"
  type        = string
}

variable "domain_name" {
  description = "도메인 이름"
  type        = string
}

variable "fe_domain_name" {
  description = "fe 도메인 이름"
  type        = string
}

variable "be_domain_name" {
  description = "fe 도메인 이름"
  type        = string
}

variable "fe_cdn_domain_name" {
  description = "CloudFront 배포의 Domain name"
  type        = string
}

variable "fe_cdn_domain_zone_id" {
  description = "CloudFront 배포의 Hosted Zone ID"
  type        = string
}

variable "be_alb_dns_name" {
  description = "CloudFront 배포의 Domain name"
  type        = string
}

variable "be_alb_zone_id" {
  description = "CloudFront 배포의 Hosted Zone ID"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}