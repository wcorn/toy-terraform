output "db_instance_endpoint" {
  description = "DB Endpoint"
  value = aws_db_instance.mydb.endpoint
}

output "db_instance_username" {
  description = "DB Username"
  value = aws_db_instance.mydb.username
}

output "db_instance_password" {
  description = "DB Password"
  value = aws_db_instance.mydb.password
}
