# ECR Repository Module

Creates an Amazon ECR repository for retroboard containers with secure defaults and optional lifecycle and repository policies.

## Features

- Image tag mutability toggle (immutable by default)
- Image scanning on push enabled by default
- Encryption with AES256 by default or KMS when provided
- Optional lifecycle policy (JSON) and repository policy (JSON)
- Optional force delete to remove repositories with images
- Standard tagging via a `tags` map

## Usage

```hcl
module "ecr_repository" {
  source = "./modules/ecr-repository"

  repository_name         = "retroboard"
  image_tag_mutable       = false
  image_scanning_on_push  = true
  encryption_type         = "AES256"
  lifecycle_policy        = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 30 days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
  repository_policy = null

  tags = {
    Environment = "prod"
    Project     = "retroboard"
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
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| image_tag_mutable | Whether image tags can be overwritten. Defaults to immutable for safety | `bool` | `false` | no |
| image_scanning_on_push | Enable image scanning on push | `bool` | `true` | no |
| encryption_type | Encryption type for the repository. Use AES256 or KMS | `string` | `AES256` | no |
| kms_key_id | KMS key ARN to use when encryption_type is KMS | `string` | `null` | no |
| lifecycle_policy | JSON lifecycle policy document for the repository | `string` | `null` | no |
| repository_policy | JSON repository policy document | `string` | `null` | no |
| force_delete | Delete repository even if images exist | `bool` | `false` | no |
| tags | A map of tags to apply to the repository | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | URL to push and pull images from the repository |
| repository_arn | ARN of the ECR repository |
| repository_name | Name of the ECR repository |

## Testing

This module ships with unit and integration tests runnable with Terraform 1.8+:

```bash
cd modules/ecr-repository
terraform test
```

The integration test creates a repository configuration with scan-on-push enabled and a lifecycle policy to assert key attributes without deploying real resources.
