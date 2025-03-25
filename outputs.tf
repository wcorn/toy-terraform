output "ssh_command" {
  description = "openvpn ssh 접속 커맨드"
  value = module.openvpn.ssh_command
}

output "db_instance_endpoint" {
  description = "db 접근 endpoint"
  value = module.database.db_instance_endpoint
}