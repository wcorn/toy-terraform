output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "public_subnet_a_id" {
  description = "NAT와 연결된 Public Subnet ID"
  value = aws_subnet.public[0].id
}

output "db_subnet_ids" {
  description = "DB의 Subnet ID 배열"
  value = aws_subnet.db[*].id
}


output "public_subnet_ids" {
  description = "Public Subnet ID 배열"
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet ID 배열"
  value = aws_subnet.private[*].id
}
