provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Provisioner = "Terraform"
      Owner       = "GameChallenge"
    }
  }
}


data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

module "vpc_md" {
  source             = "./modules/vpc_module"
  cidr_block_default = var.cidr_block_default
  environment        = var.environment
}

output "vpc_id" {
  value = module.vpc_md.vpc_id
}


locals {
  ingress_rules = [{
    description : "Port 80",
    port : 80
    }, {
    description : "Port 443",
    port : 443
  }]
}

resource "aws_security_group" "main" {
  name   = "core_sg"
  vpc_id = module.vpc_md.vpc_id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
