# Unit tests for networking-basics module

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

run "creates_expected_subnet_count" {
  command = plan

  variables {
    cidr               = "10.0.0.0/24"
    az_count           = 2
    create_nat_gateway = false
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Public subnet count should match az_count."
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Private subnet count should match az_count."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "NAT gateways should not be created when create_nat_gateway is false."
  }
}

run "invalid_cidr_fails_validation" {
  command = plan

  variables {
    cidr     = "10.0.0.0"
    az_count = 2
  }

  expect_failures = [
    var.cidr
  ]
}
