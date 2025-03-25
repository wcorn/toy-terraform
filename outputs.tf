output "ssh_command" {
  value = module.openvpn.ssh_command
}

output "db_instance_endpoint" {
  value = module.database.db_instance_endpoint
}
