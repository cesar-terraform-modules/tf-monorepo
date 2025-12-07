# ECS Task IAM Module

This module provisions IAM task and execution roles for ECS services with least-privilege policies for common API, worker, and notification workloads.

## Features

- Task role with opt-in access to DynamoDB tables, SQS queues, SNS topics, SES templated email, and delegated role assumption
- Execution role scoped to CloudWatch Logs write and ECR image pulls
- Policies limited to provided ARNs, including separate ECR auth token handling
- Consistent tagging through a shared `tags` map

## Usage

```hcl
module "ecs_task_iam" {
  source = "./modules/ecs-task-iam"

  name = "orders-api"

  enable_dynamodb         = true
  dynamodb_table_arns     = ["arn:aws:dynamodb:us-east-1:123456789012:table/orders"]
  enable_sqs_send_receive = true
  sqs_queue_arns          = ["arn:aws:sqs:us-east-1:123456789012:email-queue"]
  enable_sns_publish      = true
  sns_topic_arns          = ["arn:aws:sns:us-east-1:123456789012:slack-alerts"]
  enable_ses_templated_email = true
  ses_identity_arns          = ["arn:aws:ses:us-east-1:123456789012:identity/example.com"]
  enable_sts_assume_role     = true
  assumable_role_arns        = ["arn:aws:iam::123456789012:role/cross-account-role"]

  cloudwatch_log_group_arns = ["arn:aws:logs:us-east-1:123456789012:log-group:/ecs/orders:*"]
  ecr_repository_arns       = ["arn:aws:ecr:us-east-1:123456789012:repository/orders"]

  tags = {
    Environment = "production"
    Service     = "orders"
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
| name | Base name used for IAM roles and policies created by this module | `string` | n/a | yes |
| enable_dynamodb | Enable DynamoDB permissions for the provided tables | `bool` | `false` | no |
| dynamodb_table_arns | List of DynamoDB table ARNs the task role can access | `list(string)` | `[]` | no |
| enable_sqs_send_receive | Enable SQS send/receive permissions for the provided queues | `bool` | `false` | no |
| sqs_queue_arns | List of SQS queue ARNs the task role can interact with | `list(string)` | `[]` | no |
| enable_sns_publish | Enable SNS publish permissions for the provided topics | `bool` | `false` | no |
| sns_topic_arns | List of SNS topic ARNs the task role can publish to | `list(string)` | `[]` | no |
| enable_ses_templated_email | Enable SES templated email permissions for the provided identities | `bool` | `false` | no |
| ses_identity_arns | List of SES identity ARNs allowed for templated email sending | `list(string)` | `[]` | no |
| enable_sts_assume_role | Enable sts:AssumeRole for the provided role ARNs | `bool` | `false` | no |
| assumable_role_arns | List of role ARNs the task role is allowed to assume | `list(string)` | `[]` | no |
| enable_cloudwatch_logs | Enable CloudWatch Logs permissions on the provided log groups for the execution role | `bool` | `true` | no |
| cloudwatch_log_group_arns | List of CloudWatch Log Group ARNs the execution role can write to | `list(string)` | `[]` | no |
| enable_ecr_pull | Enable ECR pull permissions on the provided repositories for the execution role | `bool` | `true` | no |
| ecr_repository_arns | List of ECR repository ARNs the execution role can pull images from | `list(string)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| task_role_arn | ARN of the IAM task role |
| execution_role_arn | ARN of the IAM execution role |
| policy_arns | ARNs of the IAM policies created by the module (task, execution) |

## Testing

This module includes unit tests for policy generation and an integration test that plans role creation with sample ARNs.

Run tests:

```bash
cd modules/ecs-task-iam
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.
