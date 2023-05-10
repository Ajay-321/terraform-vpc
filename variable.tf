variable "prefix" {
  default = "terraform-practice"

}

variable "region" {
  default = "us-east-1"

}

variable "vpc_cidr" {
  default = "10.0.0.0/16"

}

variable "azs" {
  type    = list(string)
  default = []

}
variable "private_subnets" {
  type    = list(string)
  default = []

}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "profile_name" {
  type = string

}