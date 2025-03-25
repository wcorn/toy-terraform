variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "OpenVPN 서버를 배포할 Public Subnet ID"
  type        = string
}

variable "openvpn_ami" {
  description = "OpenVPN 서버에 사용할 AMI ID"
  type        = string
  default     = "ami-09a093fa2e3bfca5a"
}

variable "vpn_client_cidr" {
  description = "OpenVPN 클라이언트 IP 대역"
  type        = string
  default     = "172.27.224.0/20"
}

variable "openvpn_ingress_rules" {
  description = "OpenVPN 보안그룹 ingress 규칙"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    ssh     = { from_port = 22,   to_port = 22,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    web1    = { from_port = 943,  to_port = 943,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    web2    = { from_port = 945,  to_port = 945,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    https   = { from_port = 443,  to_port = 443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    openvpn = { from_port = 1194, to_port = 1194, protocol = "udp", cidr_blocks = ["0.0.0.0/0"] },
  }
}

variable "openvpn_egress_rules" {
  description = "OpenVPN 보안그룹 egress 규칙"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    all = { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
  }
}