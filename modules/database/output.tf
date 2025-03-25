output "db_instance_endpoint" {
  value = aws_db_instance.mydb.endpoint
}

output "db_instance_username" {
  value = aws_db_instance.mydb.username
}

output "db_instance_password" {
  value = aws_db_instance.mydb.password
}
