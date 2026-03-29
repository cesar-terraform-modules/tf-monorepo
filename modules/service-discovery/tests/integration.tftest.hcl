# Integration tests for service-discovery module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_retroboard_services" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-99887766"
    services = [
      {
        name    = "email-summary"
        dns_ttl = 10
      },
      {
        name    = "notification-service"
        dns_ttl = 15
      },
      {
        name    = "api"
        dns_ttl = 5
      }
    ]
    tags = {
      Environment = "integration"
      Project     = "retroboard"
    }
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.name == "retroboard.local"
    error_message = "Namespace should be retroboard.local"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.vpc == "vpc-99887766"
    error_message = "Namespace should be associated with the provided VPC"
  }

  assert {
    condition     = length(aws_service_discovery_service.this) == 3
    error_message = "Three services should be created"
  }

  assert {
    condition     = toset(keys(aws_service_discovery_service.this)) == toset(["email-summary", "notification-service", "api"])
    error_message = "All three services should be present by name"
  }

  assert {
    condition     = one(aws_service_discovery_service.this["api"].dns_config[0].dns_records[*].ttl) == 5
    error_message = "API service DNS TTL should be 5"
  }

  assert {
    condition     = length(output.service_arns) == 3
    error_message = "service_arns output should contain three entries"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.tags["Project"] == "retroboard"
    error_message = "Tags should be applied to namespace"
  }
}

run "integration_namespace_only" {
  command = plan

  variables {
    namespace_name = "internal.example.com"
    vpc_id         = "vpc-11223344"
    tags = {
      Environment = "staging"
    }
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.name == "internal.example.com"
    error_message = "Namespace name should match"
  }

  assert {
    condition     = length(aws_service_discovery_service.this) == 0
    error_message = "No services should be created when services list is empty"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.tags["Environment"] == "staging"
    error_message = "Tags should be applied to the namespace"
  }
}
