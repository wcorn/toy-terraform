variable "backend_asg" {
  description = "backend asg"
  type = string
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "backend에 사용할 Subnet ID"
  type        = list(string)
}

variable "db_instance_endpoint" {
  description = "database의 endpoint"
  type = string
}

variable "db_instance_username" {
  description = "database의 username"
  type = string
}

variable "db_instance_password" {
  description = "database의 password"
  type = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}