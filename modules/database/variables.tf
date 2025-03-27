variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "DB에 사용할 Subnet ID 리스트"
  type        = list(string)
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}