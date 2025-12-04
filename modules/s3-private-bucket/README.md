# S3 Private Bucket Module

This module creates a private S3 bucket with security best practices enabled by default.

## Features

- **Private by default**: All public access is blocked
- **Encryption**: Server-side encryption enabled (AES256 or KMS)
- **Versioning**: Optional versioning support
- **Lifecycle policies**: Optional lifecycle rules for object transitions and expiration

## Usage

```hcl
module "private_bucket" {
  source = "./modules/s3-private-bucket"

  bucket_name        = "my-private-bucket"
  versioning_enabled = true
  
  lifecycle_rules = [
    {
      id              = "archive-old-objects"
      enabled         = true
      expiration_days = 90
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]
    }
  ]

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
| bucket_name | The name of the S3 bucket. Must be globally unique | `string` | n/a | yes |
| force_destroy | A boolean that indicates all objects should be deleted from the bucket | `bool` | `false` | no |
| versioning_enabled | Enable versioning for the S3 bucket | `bool` | `true` | no |
| kms_key_id | The AWS KMS key ID to use for server-side encryption | `string` | `null` | no |
| lifecycle_rules | List of lifecycle rules for the bucket | `list(object)` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |

## Testing

This module includes comprehensive test coverage:

- **Unit tests**: Validate module configuration, encryption settings, versioning, lifecycle rules, and tag application
- **Integration tests**: Test complete bucket deployments with various configurations

Run tests:
```bash
cd modules/s3-private-bucket
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.
