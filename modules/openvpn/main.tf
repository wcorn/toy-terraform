# OpenVPN  보안 그룹
resource "aws_security_group" "openvpn_sg" {
  name        = "openvpn-sg-${var.env}"
  description = "Security group for OpenVPN server"
  vpc_id      = var.vpc_id
  tags = merge(var.common_tags, {
    Name = "openvpn-sg-${var.env}"
  })
}

# OpenVPN 보안그룹 ingress 규칙 
resource "aws_security_group_rule" "openvpn_ingress_rule" {
  for_each = var.openvpn_ingress_rules

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.openvpn_sg.id
}

# OpenVPN 보안그룹 egress 규칙 
resource "aws_security_group_rule" "openvpn_egress_rule" {
  for_each = var.openvpn_egress_rules

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.openvpn_sg.id
}

# SSH Key 생성 (TLS provider 사용)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn-key-${var.env}"
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags = merge(var.common_tags, {
    Name = "openvpn-key-${var.env}"
  })
}
resource "random_password" "ssh_key" {
  length  = 16
  special = false
}
resource "aws_secretsmanager_secret" "openvpn_private_key" {
  name = "openvpn-key-${var.env}-${random_password.ssh_key.result}"
  tags = merge(var.common_tags, {
    Name = "openvpn-key-sm-${var.env}"
  })
}

resource "aws_secretsmanager_secret_version" "openvpn_private_key_version" {
  secret_id     = aws_secretsmanager_secret.openvpn_private_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}

# OpenVPN 서버 EC2 인스턴스
resource "aws_instance" "openvpn_server" {
  ami                         = var.openvpn_ami
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.openvpn_sg.id]
  key_name                    = aws_key_pair.openvpn.key_name
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "openvpn-ec2-${var.env}"
  })
}

# Elastic IP 할당
resource "aws_eip" "openvpn_eip" {
  instance = aws_instance.openvpn_server.id
  tags = merge(var.common_tags, {
    Name = "openvpn-ip-${var.env}"
  })
}
