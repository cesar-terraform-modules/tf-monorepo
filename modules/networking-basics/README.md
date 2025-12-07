# Networking Basics Module

Creates a simple VPC with public and private subnets, optional NAT gateways, route tables, and the default security group suitable for ECS or other workloads.

## Features
- VPC with DNS support enabled
- Evenly spread public and private subnets across the requested AZ count
- Optional NAT gateway per public subnet for private egress
- Internet gateway and route tables wired for public/private tiers
- Default security group with egress open and no ingress

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
