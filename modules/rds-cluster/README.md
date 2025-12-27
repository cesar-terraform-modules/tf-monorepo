# RDS Cluster Module

This module creates an Amazon RDS Aurora Cluster with security best practices enabled by default. It supports both Aurora PostgreSQL and Aurora MySQL engines, with configurable read replicas and comprehensive security features.

## Features

- **Network Integration**: Uses existing network setup with multiple subnets via data sources
- **Subnet Reuse**: Exposes subnet data sources for reuse in other resources
- **Security Best Practices**:
  - Encryption at rest enabled by default
  - Configurable KMS encryption keys
  - Security groups with configurable ingress rules
  - CloudWatch logs export
  - Enhanced monitoring support
  - Performance Insights support
  - Deletion protection enabled by default
- **Read Replicas**: Configurable number of read replicas (0 or more) with maximum limit validation
- **Backup & Recovery**: Automated backups with configurable retention
- **High Availability**: Multi-AZ support with configurable instance counts

## Usage

### Basic Example

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "mydb"
  master_username    = "admin"
  master_password    = "SecurePassword123!" # Use secrets manager in production

  vpc_id = "vpc-12345678"

  # Use existing subnets via data source
  subnet_filter = {
    name   = "tag:Name"
    values = ["private-*"]
  }

  # Security configuration
  allowed_cidr_blocks = ["10.0.0.0/16"]
  allowed_security_groups = ["sg-12345678"]

  # Instance configuration
  db_cluster_instance_class = "db.r6g.large"
  instance_count            = 2
  read_replica_count        = 2
  max_read_replica_count    = 5

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Using Existing Subnets

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  master_username    = "admin"
  master_password    = "SecurePassword123!"

  vpc_id    = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11223344"]

  tags = {
    Environment = "production"
  }
}
```

### With Custom Security Groups

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  master_username    = "admin"
  master_password    = "SecurePassword123!"

  vpc_id = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Use existing security group instead of creating one
  create_security_group = false
  security_group_ids    = ["sg-existing123"]

  tags = {
    Environment = "production"
  }
}
```

### With Enhanced Monitoring and Performance Insights

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  master_username    = "admin"
  master_password    = "SecurePassword123!"

  vpc_id    = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Enhanced monitoring
  monitoring_interval = 60

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
  }
}
```

### With KMS Encryption

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  master_username    = "admin"
  master_password    = "SecurePassword123!"

  vpc_id    = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # KMS encryption
  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
  }
}
```

### No Read Replicas

```hcl
module "rds_cluster" {
  source = "./modules/rds-cluster"

  cluster_identifier = "my-aurora-cluster"
  engine             = "aurora-postgresql"
  master_username    = "admin"
  master_password    = "SecurePassword123!"

  vpc_id    = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # No read replicas
  read_replica_count = 0
  instance_count     = 1

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
| cluster_identifier | The cluster identifier. If omitted, Terraform will assign a random, unique identifier | `string` | n/a | yes |
| master_username | Username for the master DB user | `string` | n/a | yes |
| vpc_id | ID of the VPC where to create the RDS cluster | `string` | n/a | yes |
| allow_major_version_upgrade | Enable to allow major engine version upgrades when changing engine versions | `bool` | `false` | no |
| allowed_cidr_blocks | List of CIDR blocks allowed to access the RDS cluster | `list(string)` | `[]` | no |
| allowed_security_groups | List of security group IDs allowed to access the RDS cluster | `list(string)` | `[]` | no |
| apply_immediately | Specifies whether any cluster modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| auto_minor_version_upgrade | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | `bool` | `true` | no |
| backup_retention_period | The days to retain backups for. Default 7 days | `number` | `7` | no |
| copy_tags_to_snapshot | Copy all Cluster tags to snapshots | `bool` | `true` | no |
| create_security_group | Whether to create a security group for the RDS cluster | `bool` | `true` | no |
| database_name | Name for an automatically created database on cluster creation | `string` | `null` | no |
| db_cluster_instance_class | The instance class to use for the RDS cluster instances | `string` | `"db.r6g.large"` | no |
| db_cluster_parameter_group_name | The name of the DB cluster parameter group to associate with this cluster | `string` | `null` | no |
| db_parameter_group_name | The name of the DB parameter group to associate with this cluster instances | `string` | `null` | no |
| deletion_protection | If the DB cluster should have deletion protection enabled | `bool` | `true` | no |
| enabled_cloudwatch_logs_exports | List of log types to export to cloudwatch. If omitted, no logs will be exported | `list(string)` | `["postgresql", "upgrade"]` | no |
| engine | The name of the database engine to be used for this DB cluster | `string` | `"aurora-postgresql"` | no |
| engine_version | The database engine version | `string` | `null` | no |
| final_snapshot_identifier | The name of your final DB snapshot when this DB cluster is deleted | `string` | `null` | no |
| instance_count | Number of cluster instances to create (including the primary). Minimum 1 | `number` | `1` | no |
| kms_key_id | The ARN for the KMS encryption key. When specifying kms_key_id, storage_encrypted needs to be set to true | `string` | `null` | no |
| master_password | Password for the master DB user | `string` | `null` | no |
| max_read_replica_count | Maximum number of read replicas allowed. Used for validation | `number` | `15` | no |
| monitoring_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected | `number` | `60` | no |
| monitoring_role_arn | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `string` | `null` | no |
| performance_insights_enabled | Specifies whether Performance Insights is enabled or not | `bool` | `false` | no |
| performance_insights_kms_key_id | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| performance_insights_retention_period | Amount of time in days to retain Performance Insights data | `number` | `7` | no |
| port | The port on which the DB accepts connections | `number` | `null` | no |
| preferred_backup_window | The daily time range during which automated backups are created if automated backups are enabled | `string` | `"03:00-04:00"` | no |
| preferred_maintenance_window | The weekly time range during which system maintenance can occur | `string` | `"sun:04:00-sun:05:00"` | no |
| publicly_accessible | Whether the cluster instances are publicly accessible | `bool` | `false` | no |
| read_replica_count | Number of read replicas to create. Can be 0 or more | `number` | `0` | no |
| security_group_description | Description of the security group | `string` | `"Security group for RDS cluster"` | no |
| security_group_ids | List of security group IDs to associate with the cluster. If not provided, will create a security group | `list(string)` | `null` | no |
| security_group_name | Name of the security group to create. If not provided, will use cluster identifier | `string` | `null` | no |
| serverlessv2_scaling_configuration | Nested attribute with scaling properties of an Aurora Serverless v2 DB cluster | `object` | `null` | no |
| skip_final_snapshot | Determines whether a final DB snapshot is created before the DB cluster is deleted | `bool` | `false` | no |
| snapshot_identifier | Specifies whether or not to create this cluster from a snapshot | `string` | `null` | no |
| storage_encrypted | Specifies whether the DB cluster is encrypted | `bool` | `true` | no |
| subnet_filter | Map of filters to use when fetching subnets via data source. Used when subnet_ids is not provided | `object` | `null` | no |
| subnet_group_name | Name of the DB subnet group. If not provided, will create one | `string` | `null` | no |
| subnet_group_tags | Additional tags for the DB subnet group | `map(string)` | `{}` | no |
| subnet_ids | List of subnet IDs to use for the DB subnet group. If not provided, will use data source to fetch subnets | `list(string)` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_arn | Amazon Resource Name (ARN) of cluster |
| cluster_database_name | Name for an automatically created database on cluster creation |
| cluster_endpoint | The RDS Cluster Endpoint |
| cluster_hosted_zone_id | The Route53 Hosted Zone ID of the endpoint |
| cluster_id | The RDS Cluster Identifier |
| cluster_instance_arns | List of ARNs of the RDS cluster instances |
| cluster_instance_endpoints | List of RDS cluster instance endpoints |
| cluster_instance_ids | List of RDS cluster instance identifiers |
| cluster_master_username | The master username for the database |
| cluster_port | The database port |
| cluster_reader_endpoint | The RDS Cluster Reader Endpoint |
| cluster_resource_id | The RDS Cluster Resource ID |
| monitoring_role_arn | The ARN of the IAM role for enhanced monitoring |
| primary_instance_id | ID of the primary cluster instance |
| read_replica_count | Number of read replicas created |
| read_replica_instance_ids | List of read replica instance IDs |
| security_group_arn | The ARN of the security group created for the RDS cluster |
| security_group_id | The ID of the security group created for the RDS cluster |
| security_group_ids | List of all security group IDs associated with the cluster |
| subnet_group_arn | The ARN of the db subnet group |
| subnet_group_id | The db subnet group name |
| subnet_ids | List of subnet IDs used by the RDS cluster |
| subnets | Map of subnet details fetched via data source, keyed by subnet ID |

## Security Best Practices

This module implements several security best practices by default:

1. **Encryption at Rest**: Enabled by default (`storage_encrypted = true`)
2. **Deletion Protection**: Enabled by default to prevent accidental deletion
3. **Private Subnets**: Uses private subnets by default (`publicly_accessible = false`)
4. **Security Groups**: Creates and configures security groups with least-privilege access
5. **CloudWatch Logs**: Exports database logs to CloudWatch for monitoring
6. **Enhanced Monitoring**: Supports enhanced monitoring for better visibility
7. **Backup Retention**: Configurable backup retention (default 7 days)
8. **KMS Encryption**: Supports customer-managed KMS keys for encryption

## Network Configuration

The module supports two ways to specify subnets:

1. **Direct Subnet IDs**: Provide a list of subnet IDs directly via `subnet_ids`
2. **Data Source Lookup**: Use `subnet_filter` to fetch subnets dynamically based on tags or other attributes

The subnet data sources are exposed in the outputs for reuse in other resources.

## Read Replicas

- Set `read_replica_count` to control the number of read replicas (0 or more)
- Use `max_read_replica_count` to set a maximum limit (default: 15, AWS maximum)
- The module validates that `read_replica_count` does not exceed `max_read_replica_count`
- Read replicas are created as additional cluster instances

## Testing

This module includes comprehensive test coverage:

- **Unit tests**: Validate module configuration, security settings, read replica limits, and subnet handling
- **Integration tests**: Test complete cluster deployments with various configurations

Run tests:
```bash
cd modules/rds-cluster
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.

## Notes

- At least 2 subnets are required for RDS cluster (across multiple availability zones)
- When using `subnet_filter`, ensure the filter returns at least 2 subnets
- Master password should be stored securely (e.g., AWS Secrets Manager) and not hardcoded
- For production use, consider using AWS Secrets Manager for password management
- The module creates an IAM role for enhanced monitoring if `monitoring_interval > 0` and `monitoring_role_arn` is not provided

