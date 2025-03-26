output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}