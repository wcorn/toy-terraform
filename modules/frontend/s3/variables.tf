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