variable "fe_bucket" {
  description = "fe bucket name"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}