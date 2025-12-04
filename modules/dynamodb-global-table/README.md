# DynamoDB Global Table Module

This module creates a DynamoDB table with optional global table support for multi-region replication.

## Features

- **Global replication**: Configure replicas across multiple AWS regions
- **Flexible billing**: Support for both PAY_PER_REQUEST and PROVISIONED billing modes
- **Encryption**: Server-side encryption with optional KMS keys
- **Point-in-time recovery**: Enabled by default
- **Streams**: DynamoDB streams enabled for replication
- **Global Secondary Indexes**: Support for GSIs
- **TTL**: Optional time-to-live configuration

## Usage

### Simple table with on-demand billing

```hcl
module "users_table" {
  source = "./modules/dynamodb-global-table"

  table_name   = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  
  attributes = [
    {
      name = "user_id"
      type = "S"
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Global table with replicas

```hcl
module "global_users_table" {
  source = "./modules/dynamodb-global-table"

  table_name   = "users-global"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "timestamp"
  
  attributes = [
    {
      name = "user_id"
      type = "S"
    },
    {
      name = "timestamp"
      type = "N"
    },
    {
      name = "email"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "email-index"
      hash_key        = "email"
      projection_type = "ALL"
    }
  ]

  replica_regions = ["us-west-2", "eu-west-1", "ap-southeast-1"]

  point_in_time_recovery_enabled = true
  ttl_enabled                    = true
  ttl_attribute_name             = "expiry_time"

  tags = {
    Environment = "production"
    Project     = "my-project"
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
| table_name | The name of the DynamoDB table | `string` | n/a | yes |
| hash_key | The attribute to use as the hash (partition) key | `string` | n/a | yes |
| attributes | List of nested attribute definitions | `list(object)` | n/a | yes |
| billing_mode | Controls how you are charged for read and write throughput | `string` | `"PAY_PER_REQUEST"` | no |
| range_key | The attribute to use as the range (sort) key | `string` | `null` | no |
| read_capacity | The number of read units for this table | `number` | `5` | no |
| write_capacity | The number of write units for this table | `number` | `5` | no |
| global_secondary_indexes | List of global secondary indexes | `list(object)` | `[]` | no |
| point_in_time_recovery_enabled | Whether to enable point-in-time recovery | `bool` | `true` | no |
| encryption_enabled | Enable encryption at rest | `bool` | `true` | no |
| kms_key_arn | The ARN of the CMK for encryption | `string` | `null` | no |
| ttl_enabled | Whether TTL is enabled | `bool` | `false` | no |
| ttl_attribute_name | The name of the table attribute to store the TTL timestamp | `string` | `""` | no |
| replica_regions | List of regions to create replicas in for global table | `list(string)` | `[]` | no |
| replica_kms_key_arns | Map of region to KMS key ARN for replica encryption | `map(string)` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| table_id | The name of the table |
| table_arn | The ARN of the table |
| table_stream_arn | The ARN of the table stream |
| table_stream_label | The timestamp of the table stream |

## Testing

This module includes comprehensive test coverage:

- **Unit tests**: Validate table configuration, billing modes, GSI setup, multi-region replication, encryption, PITR, TTL, and tag application
- **Integration tests**: Test complete global table deployments with various configurations including multi-region setups

Run tests:
```bash
cd modules/dynamodb-global-table
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.
