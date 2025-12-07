# Networking Basics Module

Creates a simple VPC with public and private subnets, optional NAT gateways, route tables, and the default security group suitable for ECS or other workloads.

## Features
- VPC with DNS support enabled
- Evenly spread public and private subnets across the requested AZ count
- Optional NAT gateway per public subnet for private egress
- Internet gateway and route tables wired for public/private tiers
- Default security group with egress restricted to the VPC CIDR (configurable) and no ingress
- VPC Flow Logs enabled by default for REJECT traffic to CloudWatch Logs with configurable retention

## Usage

```hcl
module "networking" {
  source = "./modules/networking-basics"

  cidr               = "10.0.0.0/24"
  az_count           = 2
  create_nat_gateway = true

  tags = {
    Environment = "dev"
    Project     = "sample"
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
| cidr | CIDR block for the VPC (e.g., 10.0.0.0/24) | `string` | n/a | yes |
| az_count | Number of availability zones to spread subnets across | `number` | `2` | no |
| create_nat_gateway | Whether to create a NAT gateway per public subnet for private egress | `bool` | `false` | no |
| default_sg_egress_cidr_blocks | IPv4 CIDR blocks allowed for default security group egress; defaults to the VPC CIDR when not set. | `list(string)` | `[]` | no |
| default_sg_egress_ipv6_cidr_blocks | IPv6 CIDR blocks allowed for default security group egress. | `list(string)` | `[]` | no |
| enable_flow_logs | Enable VPC Flow Logs to CloudWatch Logs (recommended for auditability). | `bool` | `true` | no |
| flow_logs_retention_in_days | Retention period (in days) for the VPC Flow Logs CloudWatch Log Group. | `number` | `90` | no |
| flow_logs_traffic_type | Traffic type to capture for VPC Flow Logs. | `string` | `"REJECT"` | no |
| tags | A map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| nat_gateway_ids | IDs of NAT gateways (empty if not created) |
| default_sg_id | ID of the VPC default security group |

## Testing

This module ships with unit and integration tests runnable via `terraform test`:

```bash
cd modules/networking-basics
terraform test
```

See [TESTING.md](../../TESTING.md) for more details.
