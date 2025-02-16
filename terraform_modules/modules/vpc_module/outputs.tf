

output "vpc_id" {
  description = "The ID for vpc"
  value       = aws_vpc.vpc_md.id
}
