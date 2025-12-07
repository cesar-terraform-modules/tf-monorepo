# Integration test for ecs-task-iam module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_full_permissions" {
  command = plan

  variables {
    name                       = "integration-example"
    enable_dynamodb            = true
    dynamodb_table_arns        = ["arn:aws:dynamodb:us-east-1:333333333333:table/orders"]
    enable_sqs_send_receive    = true
    sqs_queue_arns             = ["arn:aws:sqs:us-east-1:333333333333:queue/email"]
    enable_sns_publish         = true
    sns_topic_arns             = ["arn:aws:sns:us-east-1:333333333333:topic/slack"]
    enable_ses_templated_email = true
    ses_identity_arns          = ["arn:aws:ses:us-east-1:333333333333:identity/example.com"]
    cloudwatch_log_group_arns  = ["arn:aws:logs:us-east-1:333333333333:log-group:/ecs/integration:*"]
    ecr_repository_arns        = ["arn:aws:ecr:us-east-1:333333333333:repository/integration"]
    enable_sts_assume_role     = true
    assumable_role_arns        = ["arn:aws:iam::333333333333:role/delegate"]
    tags = {
      Environment = "integration"
      Service     = "example"
    }
  }

  assert {
    condition     = aws_iam_role.task.name == "integration-example-task-role"
    error_message = "Task role name should include the provided base name"
  }

  assert {
    condition     = aws_iam_role.execution.name == "integration-example-execution-role"
    error_message = "Execution role name should include the provided base name"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.task.role == aws_iam_role.task.name
    error_message = "Task policy attachment should reference the task role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.execution.role == aws_iam_role.execution.name
    error_message = "Execution policy attachment should reference the execution role"
  }

  assert {
    condition     = toset([for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s.sid]) == toset(["DynamoDBAccess", "SqsSendReceive", "SnsPublish", "SesTemplatedEmail", "AssumeDelegatedRoles"])
    error_message = "Task policy should include all enabled statements"
  }

  assert {
    condition     = toset([for s in jsondecode(aws_iam_policy.execution_policy.policy).Statement : s.sid]) == toset(["CloudWatchLogs", "EcrGetAuthToken", "EcrPullAccess"])
    error_message = "Execution policy should include logs and ECR statements"
  }
}
