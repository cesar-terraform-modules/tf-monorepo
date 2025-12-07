# Unit tests for ecs-task-iam module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "task_policy_only_sns" {
  command = plan

  variables {
    name                       = "unit-sns"
    enable_sns_publish         = true
    sns_topic_arns             = ["arn:aws:sns:us-east-1:111111111111:alerts"]
    cloudwatch_log_group_arns  = ["arn:aws:logs:us-east-1:111111111111:log-group:/ecs/unit:*"]
    ecr_repository_arns        = ["arn:aws:ecr:us-east-1:111111111111:repository/unit"]
    enable_cloudwatch_logs     = true
    enable_ecr_pull            = true
    enable_dynamodb            = false
    enable_sqs_send_receive    = false
    enable_ses_templated_email = false
    enable_sts_assume_role     = false
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s
    ]) == 1
    error_message = "Task policy should only contain one statement when only SNS is enabled"
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s
      if s.sid == "SnsPublish" && length([for a in s.actions : a if a == "sns:Publish"]) == 1 && length(s.resources) == 1 && s.resources[0] == "arn:aws:sns:us-east-1:111111111111:alerts"
    ]) == 1
    error_message = "SNS publish statement should be scoped to provided topic ARN"
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.execution_policy.policy).Statement : s
    ]) == 3
    error_message = "Execution policy should include CloudWatch Logs and ECR statements"
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.execution_policy.policy).Statement : s
      if s.sid == "CloudWatchLogs" && contains(s.actions, "logs:CreateLogStream") && contains(s.resources, "arn:aws:logs:us-east-1:111111111111:log-group:/ecs/unit:*")
    ]) == 1
    error_message = "CloudWatch Logs statement should target provided log group ARN"
  }
}

run "task_policy_combined_permissions" {
  command = plan

  variables {
    name                      = "unit-combined"
    enable_dynamodb           = true
    dynamodb_table_arns       = ["arn:aws:dynamodb:us-east-1:222222222222:table/orders"]
    enable_sqs_send_receive   = true
    sqs_queue_arns            = ["arn:aws:sqs:us-east-1:222222222222:queue/email"]
    enable_sts_assume_role    = true
    assumable_role_arns       = ["arn:aws:iam::222222222222:role/delegate"]
    cloudwatch_log_group_arns = ["arn:aws:logs:us-east-1:222222222222:log-group:/ecs/unit:*"]
    ecr_repository_arns       = ["arn:aws:ecr:us-east-1:222222222222:repository/unit"]
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s.sid
      if s.sid == "DynamoDBAccess" || s.sid == "SqsSendReceive" || s.sid == "AssumeDelegatedRoles"
    ]) == 3
    error_message = "Task policy should include DynamoDB, SQS, and STS statements"
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s
      if s.sid == "SqsSendReceive" && contains(s.resources, "arn:aws:sqs:us-east-1:222222222222:queue/email")
    ]) == 1
    error_message = "SQS statement should be scoped to the provided queue ARN"
  }

  assert {
    condition = length([
      for s in jsondecode(aws_iam_policy.task_policy.policy).Statement : s
      if s.sid == "AssumeDelegatedRoles" && contains(s.actions, "sts:AssumeRole") && contains(s.resources, "arn:aws:iam::222222222222:role/delegate")
    ]) == 1
    error_message = "STS assume role statement should be present and scoped to provided role"
  }
}
