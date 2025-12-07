# Integration test for networking-basics module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }
}

run "creates_vpc_with_nat_and_route_tables" {
  command = plan

  variables {
    cidr               = "10.0.0.0/24"
    az_count           = 2
    create_nat_gateway = true
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/24"
    error_message = "VPC should use the provided CIDR block."
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Module should create two public and two private subnets."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "NAT gateways should be created for each public subnet."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 2 && length(aws_route_table_association.private) == 2
    error_message = "All subnets should be associated with their route tables."
  }

  assert {
    condition = anytrue([
      for rule in aws_default_security_group.this.egress : contains(rule.cidr_blocks, "0.0.0.0/0")
    ])
    error_message = "Default security group should allow outbound traffic."
  }
}
