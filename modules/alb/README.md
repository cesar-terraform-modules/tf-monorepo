# ALB Module

This module creates an AWS Application Load Balancer with security groups, target groups, HTTP/HTTPS listeners, and optional path-based routing rules. Designed for use with Fargate (target_type=ip) workloads.

## Features

- **Flexible Exposure**: Internet-facing or internal ALB via `internal` variable
- **Security Best Practices**:
  - Security group with configurable ingress CIDR blocks
  - Egress restricted to VPC CIDR
  - Modern TLS 1.3 policy for HTTPS listeners
  - HTTPS redirect support
- **Target Groups**: One or more target groups with health checks (ip target type for Fargate)
- **HTTPS Support**: Optional HTTPS listener with ACM certificate
- **Path-based Routing**: Optional listener rules for routing by URL path

## Usage

### Basic Example (HTTP only)

```hcl
module "alb" {
  source = "./modules/alb"

  name       = "my-app-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  target_groups = [
    {
      name                 = "my-app-tg"
      port                 = 8080
      protocol             = "HTTP"
      health_check_path    = "/health"
      health_check_matcher = "200"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### With HTTPS and Redirect

```hcl
module "alb" {
  source = "./modules/alb"

  name       = "my-app-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  enable_https        = true
  certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
  http_default_action = "redirect"

  target_groups = [
    {
      name                 = "my-app-tg"
      port                 = 8080
      protocol             = "HTTP"
      health_check_path    = "/health"
      health_check_matcher = "200"
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

### With Path-based Routing

```hcl
module "alb" {
  source = "./modules/alb"

  name       = "my-app-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  target_groups = [
    {
      name                 = "api-tg"
      port                 = 8080
      protocol             = "HTTP"
      health_check_path    = "/api/health"
      health_check_matcher = "200"
    },
    {
      name                 = "web-tg"
      port                 = 3000
      protocol             = "HTTP"
      health_check_path    = "/"
      health_check_matcher = "200"
    }
  ]

  listener_rules = [
    {
      priority          = 100
      path_patterns     = ["/api/*"]
      target_group_name = "api-tg"
    },
    {
      priority          = 200
      path_patterns     = ["/app/*", "/static/*"]
      target_group_name = "web-tg"
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

### Internal ALB with Restricted Access

```hcl
module "alb" {
  source = "./modules/alb"

  name          = "internal-alb"
  internal      = true
  vpc_id        = "vpc-12345678"
  subnet_ids    = ["subnet-12345678", "subnet-87654321"]
  allowed_cidrs = ["10.0.0.0/16"]

  target_groups = [
    {
      name                 = "internal-tg"
      port                 = 8080
      protocol             = "HTTP"
      health_check_path    = "/health"
      health_check_matcher = "200"
    }
  ]

  tags = {
    Environment = "production"
  }
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
| name | Name of the Application Load Balancer | `string` | n/a | yes |
| vpc_id | ID of the VPC where the ALB will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs (minimum 2) | `list(string)` | n/a | yes |
| target_groups | List of target group configurations | `list(object)` | n/a | yes |
| internal | Whether the ALB is internal | `bool` | `false` | no |
| allowed_cidrs | CIDR blocks allowed to access the ALB | `list(string)` | `["0.0.0.0/0"]` | no |
| enable_https | Whether to create an HTTPS listener | `bool` | `false` | no |
| certificate_arn | ARN of the ACM certificate for HTTPS | `string` | `null` | no |
| http_default_action | Default HTTP listener action: forward or redirect | `string` | `"forward"` | no |
| listener_rules | Path-based routing rules | `list(object)` | `[]` | no |
| health_check_interval | Interval between health checks (seconds) | `number` | `30` | no |
| health_check_healthy_threshold | Consecutive successful checks for healthy | `number` | `3` | no |
| health_check_unhealthy_threshold | Consecutive failed checks for unhealthy | `number` | `3` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ARN of the Application Load Balancer |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_zone_id | Route53 zone ID of the Application Load Balancer |
| alb_security_group_id | ID of the security group created for the ALB |
| target_group_arns | Map of target group name to ARN |
| listener_arn | ARN of the HTTP listener |
| https_listener_arn | ARN of the HTTPS listener (null if not enabled) |

## Testing

This module includes comprehensive test coverage:

- **Unit tests**: Validate module configuration, security group rules, target groups, and listener setup
- **Integration tests**: Test complete ALB deployments with various configurations

Run tests:
```bash
cd modules/alb
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.
