output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways (empty if not created)"
  value       = values(aws_nat_gateway.this)[*].id
}

output "default_sg_id" {
  description = "ID of the VPC default security group"
  value       = aws_default_security_group.this.id
}
