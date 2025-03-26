output "openvpn_sg_id" {
  description = "OpenVPN 보안그룹 id"
  value = aws_security_group.openvpn_sg.id
}