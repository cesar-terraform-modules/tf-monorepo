# SQS Queue Module

This module provisions an Amazon SQS queue for the retroboard email worker with secure defaults, optional dead-letter handling, and flexible queue policies.

## Features

- Standard queue by default, FIFO support with automatic `.fifo` suffixing
- Optional DLQ with configurable redrive policy
- Server-side encryption enabled by default (SSE-SQS) with optional customer-managed KMS key
- Tunable visibility timeout, retention, and maximum message size
- Optional queue policy attachment for least-privilege access
- Tag support for all resources

## Usage

```hcl
module "email_worker_queue" {
  source = "./modules/sqs-queue"

  queue_name                = "retroboard-email-worker"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 259200
  enable_dlq                = true
  redrive_max_receive_count = 3

  queue_policy_statements = [
    {
      sid     = "AllowSes"
      actions = ["sqs:SendMessage"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ses.amazonaws.com"]
        }
      ]
      conditions = {
        LimitSource = {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = ["arn:aws:ses:us-east-1:123456789012:identity/example.com"]
        }
      }
    }
  ]

  tags = {
    Service = "email"
    Env     = "prod"
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
| queue_name | Name for the SQS queue. If fifo_queue is true, .fifo is appended when missing. | `string` | n/a | yes |
| fifo_queue | Create the queue as FIFO. Defaults to a standard queue. | `bool` | `false` | no |
| visibility_timeout_seconds | Visibility timeout in seconds for the queue. | `number` | `30` | no |
| message_retention_seconds | How long messages are retained in seconds. | `number` | `345600` | no |
| max_message_size | The limit of how many bytes a message can contain. | `number` | `262144` | no |
| content_based_deduplication | Enables content-based deduplication for FIFO queues. | `bool` | `true` | no |
| kms_key_id | Customer managed KMS key ARN to use for encryption. When null, SQS-managed SSE is enabled. | `string` | `null` | no |
| enable_dlq | Whether to create a dead-letter queue and attach a redrive policy. | `bool` | `false` | no |
| dlq_name | Optional name for the dead-letter queue. Defaults to `<queue_name>-dlq`. | `string` | `null` | no |
| dlq_message_retention_seconds | Retention in seconds for the dead-letter queue. | `number` | `1209600` | no |
| redrive_max_receive_count | Maximum receives before moving a message to the DLQ. | `number` | `5` | no |
| queue_policy_statements | List of IAM policy statements to attach to the queue. | `list(object)` | `[]` | no |
| tags | A map of tags to add to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_id | The SQS queue ID. |
| queue_arn | The ARN of the SQS queue. |
| queue_url | The URL of the SQS queue. |
| dlq_arn | The ARN of the dead-letter queue when created. |
| dlq_url | The URL of the dead-letter queue when created. |

## Testing

Run module tests with Terraform:

```bash
cd modules/sqs-queue
terraform test
```

Unit tests validate defaults, encryption, FIFO naming, DLQ redrive configuration, and policy attachment. Integration tests cover minimal and FIFO+DLQ configurations. See [TESTING.md](../../TESTING.md) for more detail.
