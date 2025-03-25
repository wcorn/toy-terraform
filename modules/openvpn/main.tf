# OpenVPN 서버용 보안 그룹
resource "aws_security_group" "openvpn_sg" {
  name        = "openvpn-security-group"
  description = "Security group for OpenVPN server"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "openvpn_ingress_rule" {
  for_each = var.openvpn_ingress_rules

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.openvpn_sg.id
}

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
  key_name   = "openvpn_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "openvpn_key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

# OpenVPN 서버 EC2 인스턴스
resource "aws_instance" "openvpn_server" {
  ami                         = var.openvpn_ami
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.openvpn_sg.id]
  key_name                    = aws_key_pair.openvpn.key_name
  associate_public_ip_address = true

  tags = {
    Name = "OpenVPN-Server"
  }
}

# Elastic IP 할당
resource "aws_eip" "openvpn_eip" {
  instance = aws_instance.openvpn_server.id
}