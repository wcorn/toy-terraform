output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "public_subnet_a_id" {
  description = "NAT와 연결된 Public Subnet ID"
  value = aws_subnet.public[0].id
}

output "public_subnet_ids" {
  description = "Public Subnet ID 배열"
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet ID 배열"
  value = aws_subnet.private[*].id
}

output "private_route_table_id" {
  description = "Private routing table"
  value = aws_route_table.private.id
}

output "public_route_table_id" {
  description = "Public routing table"
  value = aws_route_table.public.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value = aws_vpc.this.cidr_block
}

output "private_subnets" {
  description = "private subnets"
  value = aws_subnet.private
}