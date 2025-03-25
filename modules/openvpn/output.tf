output "ssh_command" {
  description = "OpenVPN SSH 접속 명령어"
  value       = "ssh -i openvpn_key.pem openvpnas@${aws_eip.openvpn_eip.public_ip}"
}

output "openvpn_sg_id" {
  description = "OpenVPN 보안그룹 id"
  value = aws_security_group.openvpn_sg.id
}