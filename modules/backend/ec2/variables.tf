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

variable "openvpn_sg_id" {
  description = "open vpn의 sg"
  type        = string
}

variable "cert_souel_arn" {
  description = "moaboa의 seoul 인증서"
  type = string
}