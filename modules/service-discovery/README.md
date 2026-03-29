# Service Discovery Module

Creates an AWS Cloud Map private DNS namespace with service registrations for ECS Fargate service-to-service communication without a load balancer.

## Features

- Private DNS namespace backed by Route 53 within a VPC
- Multiple service registrations via a single variable
- A-record DNS with configurable TTL per service
- Custom health check for ECS-managed health reporting
- Output map of service ARNs for direct use with the fargate-ecs-bluegreen module's `service_registries` variable
- Consistent tagging with automatic `Name` tags

## Usage

```hcl
module "service_discovery" {
  source = "./modules/service-discovery"

  namespace_name = "retroboard.local"
  vpc_id         = "vpc-12345678"

  services = [
    {
      name    = "email-summary"
      dns_ttl = 10
    },
    {
      name    = "notification-service"
      dns_ttl = 15
    }
  ]

  tags = {
    Environment = "production"
    Project     = "retroboard"
  }
}

# Pass service ARNs to the ECS module
module "email_summary_ecs" {
  source = "./modules/fargate-ecs-bluegreen"

  # ... other config ...

  service_registries = [
    {
      registry_arn   = module.service_discovery.service_arns["email-summary"]
      container_name = "email-summary"
      container_port = 8080
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace_name | Name of the private DNS namespace (e.g. retroboard.local) | `string` | n/a | yes |
| vpc_id | VPC ID to associate with the private DNS namespace | `string` | n/a | yes |
| services | List of services to register. Each object includes `name` (string) and `dns_ttl` (number, default 10). | `list(object)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace_id | The ID of the private DNS namespace |
| namespace_arn | The ARN of the private DNS namespace |
| namespace_hosted_zone | The ID of the Route 53 hosted zone created for the namespace |
| service_arns | Map of service name to registry ARN, for use with ECS service_registries |

## Testing

Run unit and integration tests from the module directory:

```bash
cd modules/service-discovery
terraform test
```

See [TESTING.md](../../TESTING.md) for more details.
