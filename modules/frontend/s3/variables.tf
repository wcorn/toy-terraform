variable "fe_domain_name" {
  description = "frontend 도메인 이름"
  type        = string
}

variable "domain_name_prefix" {
  description = "도메인 이름 prefix"
  type        = string
}

variable "cert_us_arn" {
  description = "CloudFront에서 사용할 ACM 인증서 ARN"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}