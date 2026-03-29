locals {
  services = {
    for s in var.services : s.name => {
      dns_ttl = s.dns_ttl
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = var.namespace_name
  vpc  = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = var.namespace_name
    }
  )
}

resource "aws_service_discovery_service" "this" {
  for_each = local.services

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      type = "A"
      ttl  = each.value.dns_ttl
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )
}
