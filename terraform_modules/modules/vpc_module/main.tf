# Define the VPC
resource "aws_vpc" "vpc_md" {
  cidr_block = var.cidr_block_default

  tags = {
    Name        = var.cidr_block_default
    Environment = var.environment
  }
}
