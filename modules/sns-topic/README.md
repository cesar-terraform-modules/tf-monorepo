# SNS Topic Module

Creates an SNS topic for retroboard Slack alerts with optional HTTP/HTTPS and SQS subscriptions, optional topic and delivery policies, KMS encryption support, and FIFO content-based deduplication when enabled.

## Features

- Standard or FIFO SNS topic with optional content-based deduplication
- Optional KMS-managed encryption
- Optional topic policy and delivery policy inputs
- Flexible subscriptions list supporting HTTP/HTTPS endpoints and SQS queues
- Delivery and filter policies per subscription
- Tagging via provided `tags` map (includes automatic `Name`)

## Usage

```hcl
module "sns_topic" {
  source = "./modules/sns-topic"

  topic_name                  = "retroboard-slack-alerts"
  fifo_topic                  = false
  content_based_deduplication = true

  subscriptions = [
    {
      protocol = "https"
      endpoint = "https://alerts.example.com/slack"
    },
    {
      protocol             = "sqs"
      endpoint             = "arn:aws:sqs:us-east-1:123456789012:retroboard-alerts-queue"
      raw_message_delivery = true
    }
  ]

  tags = {
    Environment = "production"
    Project     = "retroboard"
  }
}
```

### FIFO example

```hcl
module "sns_topic_fifo" {
  source = "./modules/sns-topic"

  topic_name                  = "retroboard-slack-alerts.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
  kms_master_key_id           = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-5678-90ab-cdef-111122223333"
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
| topic_name | The name of the SNS topic | `string` | n/a | yes |
| display_name | The display name for the SNS topic (not supported for FIFO topics) | `string` | `null` | no |
| fifo_topic | Whether to create the topic as FIFO | `bool` | `false` | no |
| content_based_deduplication | Enable content-based deduplication for FIFO topics. Only applied when fifo_topic is true. | `bool` | `true` | no |
| kms_master_key_id | KMS key ID to use for server-side encryption of the topic | `string` | `null` | no |
| topic_policy | Optional JSON policy for the SNS topic | `string` | `null` | no |
| delivery_policy | Optional JSON delivery policy for the SNS topic | `string` | `null` | no |
| subscriptions | List of subscription definitions to attach to the topic. Each object should include `protocol` (http/https/sqs) and `endpoint`, with optional `raw_message_delivery`, `filter_policy`, and `delivery_policy`. | `any (expects list of objects)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| topic_arn | The ARN of the SNS topic |
| topic_name | The name of the SNS topic |
| subscription_arns | List of ARNs for subscriptions created by this module |

## Testing

Run unit and integration tests from the module directory:

```bash
cd modules/sns-topic
terraform test
```

See [TESTING.md](../../TESTING.md) for more details.
