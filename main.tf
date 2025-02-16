
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# data "aws_ami" "ubuntu_22_04" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   owners = ["099720109477"]
# }

locals {
  team         = "api_dev"
  application  = "demo_app"
  service_name = "ec2-${var.aws_environment}-${var.aws_region}"
}

module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = "10.0.0.0/22"
  networks = [
    {
      name     = "module_network_a"
      new_bits = 2
    },
    {
      name     = "module_network_b"
      new_bits = 2
    }
  ]
}

output "subnet_addrs" {
  value = module.subnet_addrs.network_cidr_blocks
}

# Define the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc.cidr

  tags = {
    Name        = var.vpc.name
    Environment = var.aws_environment
    Region      = data.aws_region.current.name
    Terraform   = "true"
  }
}

# Define the public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc.cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

# Define the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc.cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

# Define internet gateway for public 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name      = "demo_igw"
    Terraform = "true"
  }
}

# Define Elastic IP for nat gateway
resource "aws_eip" "nat_gateway_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name      = "demo_igw_eip"
    Terraform = "true"
  }
}

# Define nat gatway for private
resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id

  tags = {
    Name      = "demo_nat_gw"
    Terraform = "true"
  }

}


# Create route tables for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name      = "demo_public_rtb"
    Terraform = "true"
  }
}

# Create route table for pribvate subnets 
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name      = "demo_private_rtb"
    Terraform = "true"
  }
}

# Associate public subnets with public route table  
resource "aws_route_table_association" "public_subnet_association" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate private subnets with private route table  
resource "aws_route_table_association" "private_subnet_association" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}

# Create EC2 Instance in public subnet
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.sg_ssh.id, aws_security_group.sg_web_ping.id, aws_security_group.sg_web_traffic.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key_pair_generated.key_name
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.tls_generated.private_key_pem
    host        = self.public_ip
    timeout     = "4m"
  }

  lifecycle {
    ignore_changes = [security_groups]
  }

  # Provisoner to access to instance
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  # Add this to ensure instance is fully initialized  
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
      "sudo sh /tmp/assets/setup-web.sh"
    ]
  }

  tags = {
    Name      = local.service_name
    Owner     = local.team
    App       = local.service_name
    Terraform = "true"
  }
}

# Create random id 
resource "random_id" "randomness" {
  byte_length = 8
}


# Create bucket S3 
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "demo-bucket-${lower(random_id.randomness.hex)}"

  tags = {
    Name      = "demo_bucket"
    Terraform = "true"
  }
}

resource "aws_s3_bucket_ownership_controls" "demo_bucket_acl" {
  bucket = aws_s3_bucket.demo_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Create security group
resource "aws_security_group" "demo_security_group" {
  name        = "web_server_inbound"
  description = "Allow inbound traffic on tcp/443"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow 443 from the Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "demo_web_server_inbound"
    Terraform = "true"
  }

}

# Create a self-signed certificate with TLS provider
resource "tls_private_key" "tls_generated" {
  algorithm = "RSA"
}

locals {
  local_key_name = "myawskey"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.tls_generated.private_key_pem
  filename = "${local.local_key_name}.pem"
}

resource "aws_key_pair" "key_pair_generated" {
  key_name   = local.local_key_name
  public_key = tls_private_key.tls_generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

# Security Group to allow SSH to instance
resource "aws_security_group" "sg_ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "ssh from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
}

# Security Group for Web Traffic
resource "aws_security_group" "sg_web_traffic" {
  name        = "web-traffic-${terraform.workspace}"
  vpc_id      = aws_vpc.vpc.id
  description = "Web Traffic"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  egress {
    description = "allow all ip and port outbounds"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_web_ping" {
  name        = "web-ping"
  vpc_id      = aws_vpc.vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "allow icmp traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
