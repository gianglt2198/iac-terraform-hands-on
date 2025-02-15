variable "aws_environment" {
  type    = string
  default = "development"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc" {
  type = object({
    name = string
    cidr = string
  })
  default = {
    name = "demo_vpc"
    cidr = "10.0.0.0/16"
  }
}

variable "public_subnets" {
  default = {
    public_subnet_1 = 1
    public_subnet_2 = 2
    public_subnet_3 = 3
  }
}

variable "private_subnets" {
  default = {
    private_subnet_1 = 1
    private_subnet_2 = 2
    private_subnet_3 = 3
  }
}
