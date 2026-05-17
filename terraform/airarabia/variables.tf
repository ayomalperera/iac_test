variable "aws_region" {
  default = "ap-southeast-1"
}

variable "project_name" {
  default = "airarabia"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  default = "10.0.3.0/24"
}

variable "instance_type" {
  default = "t3.micro"
}



variable "ami_id" {
  default = "ami-0a56f8447277affd8"
}