variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "DB에 사용할 Subnet ID 리스트"
  type        = list(string)
}
