# Unit tests for service-discovery module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "test_namespace_creation" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-12345678"
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.name == "retroboard.local"
    error_message = "Namespace name should match input"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.vpc == "vpc-12345678"
    error_message = "VPC ID should match input"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.tags["Name"] == "retroboard.local"
    error_message = "Name tag should be applied automatically"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.tags["Environment"] == "test"
    error_message = "Custom tags should be applied"
  }
}

run "test_no_services" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-12345678"
  }

  assert {
    condition     = length(aws_service_discovery_service.this) == 0
    error_message = "No services should be created when services list is empty"
  }
}

run "test_single_service_defaults" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-12345678"
    services = [
      {
        name = "email-summary"
      }
    ]
  }

  assert {
    condition     = length(aws_service_discovery_service.this) == 1
    error_message = "One service should be created"
  }

  assert {
    condition     = aws_service_discovery_service.this["email-summary"].name == "email-summary"
    error_message = "Service name should match input"
  }

  assert {
    condition     = one(aws_service_discovery_service.this["email-summary"].dns_config[0].dns_records[*].ttl) == 10
    error_message = "DNS TTL should default to 10"
  }

  assert {
    condition     = one(aws_service_discovery_service.this["email-summary"].dns_config[0].dns_records[*].type) == "A"
    error_message = "DNS record type should be A"
  }

  assert {
    condition     = aws_service_discovery_service.this["email-summary"].dns_config[0].routing_policy == "MULTIVALUE"
    error_message = "Routing policy should be MULTIVALUE"
  }

  assert {
    condition     = length(aws_service_discovery_service.this["email-summary"].health_check_custom_config) == 1
    error_message = "Health check custom config should be present"
  }
}

run "test_multiple_services_custom_config" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-12345678"
    services = [
      {
        name    = "email-summary"
        dns_ttl = 30
      },
      {
        name    = "notification-service"
        dns_ttl = 15
      }
    ]
    tags = {
      Project = "retroboard"
    }
  }

  assert {
    condition     = length(aws_service_discovery_service.this) == 2
    error_message = "Two services should be created"
  }

  assert {
    condition     = one(aws_service_discovery_service.this["email-summary"].dns_config[0].dns_records[*].ttl) == 30
    error_message = "email-summary DNS TTL should be 30"
  }

  assert {
    condition     = one(aws_service_discovery_service.this["notification-service"].dns_config[0].dns_records[*].ttl) == 15
    error_message = "notification-service DNS TTL should be 15"
  }

  assert {
    condition     = aws_service_discovery_service.this["email-summary"].tags["Name"] == "email-summary"
    error_message = "Name tag should be set to service name"
  }

  assert {
    condition     = aws_service_discovery_service.this["notification-service"].tags["Project"] == "retroboard"
    error_message = "Custom tags should be applied to services"
  }
}

run "test_service_arns_output" {
  command = plan

  variables {
    namespace_name = "retroboard.local"
    vpc_id         = "vpc-12345678"
    services = [
      {
        name = "email-summary"
      },
      {
        name = "notification-service"
      }
    ]
  }

  assert {
    condition     = length(output.service_arns) == 2
    error_message = "service_arns output should contain two entries"
  }

  assert {
    condition     = contains(keys(output.service_arns), "email-summary")
    error_message = "service_arns should contain email-summary key"
  }

  assert {
    condition     = contains(keys(output.service_arns), "notification-service")
    error_message = "service_arns should contain notification-service key"
  }
}
