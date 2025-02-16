variable "aws_environment" {
  type = string

  validation {
    condition     = contains(["development", "staging", "production"], lower(var.aws_environment))
    error_message = "You must use an available environment"
  }

  default = "development"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ip_address" {
  type = string

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
    error_message = "Must be an IP address of the form X.X.X.X"
  }

  default = "10.0.0.0"
}

variable "phone_number" {
  type = string

  validation {
    condition     = length(var.phone_number) == 10
    error_message = "Phone number limit 10 characters"
  }
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
