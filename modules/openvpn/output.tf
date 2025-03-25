output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i openvpn_key.pem openvpnas@${aws_eip.openvpn_eip.public_ip}"
}

# OpenVPN 인스턴스의 네트워크 인터페이스 ID 등도 출력할 수 있습니다.
output "openvpn_network_interface_id" {
  value = aws_instance.openvpn_server.primary_network_interface_id
}

output "openvpn_sg_id" {
  value = aws_security_group.openvpn_sg.id
}