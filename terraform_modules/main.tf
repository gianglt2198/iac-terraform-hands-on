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
