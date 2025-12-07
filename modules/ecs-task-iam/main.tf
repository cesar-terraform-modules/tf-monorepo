locals {
  task_policy_statements = [
    for statement in [
      var.enable_dynamodb && length(var.dynamodb_table_arns) > 0 ? {
        sid       = "DynamoDBAccess"
        effect    = "Allow"
        actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"]
        resources = var.dynamodb_table_arns
      } : null,
      var.enable_sqs_send_receive && length(var.sqs_queue_arns) > 0 ? {
        sid       = "SqsSendReceive"
        effect    = "Allow"
        actions   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ChangeMessageVisibility", "sqs:ListDeadLetterSourceQueues"]
        resources = var.sqs_queue_arns
      } : null,
      var.enable_sns_publish && length(var.sns_topic_arns) > 0 ? {
        sid       = "SnsPublish"
        effect    = "Allow"
        actions   = ["sns:Publish"]
        resources = var.sns_topic_arns
      } : null,
      var.enable_ses_templated_email && length(var.ses_identity_arns) > 0 ? {
        sid       = "SesTemplatedEmail"
        effect    = "Allow"
        actions   = ["ses:SendTemplatedEmail", "ses:SendBulkTemplatedEmail"]
        resources = var.ses_identity_arns
      } : null,
      var.enable_sts_assume_role && length(var.assumable_role_arns) > 0 ? {
        sid       = "AssumeDelegatedRoles"
        effect    = "Allow"
        actions   = ["sts:AssumeRole"]
        resources = var.assumable_role_arns
      } : null
    ] : statement if statement != null
  ]

  execution_policy_statements = [
    for statement in [
      var.enable_cloudwatch_logs && length(var.cloudwatch_log_group_arns) > 0 ? {
        sid       = "CloudWatchLogs"
        effect    = "Allow"
        actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        resources = var.cloudwatch_log_group_arns
      } : null,
      var.enable_ecr_pull && length(var.ecr_repository_arns) > 0 ? {
        sid       = "EcrGetAuthToken"
        effect    = "Allow"
        actions   = ["ecr:GetAuthorizationToken"]
        resources = ["*"]
      } : null,
      var.enable_ecr_pull && length(var.ecr_repository_arns) > 0 ? {
        sid       = "EcrPullAccess"
        effect    = "Allow"
        actions   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability", "ecr:DescribeImages", "ecr:DescribeRepositories"]
        resources = var.ecr_repository_arns
      } : null
    ] : statement if statement != null
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  task_policy_document = jsonencode({
    Version   = "2012-10-17"
    Statement = local.task_policy_statements
  })

  execution_policy_document = jsonencode({
    Version   = "2012-10-17"
    Statement = local.execution_policy_statements
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task-role"
  assume_role_policy = local.assume_role_policy
  tags               = var.tags
}

resource "aws_iam_policy" "task_policy" {
  name   = "${var.name}-task-policy"
  policy = local.task_policy_document

  lifecycle {
    precondition {
      condition     = length(local.task_policy_statements) > 0
      error_message = "Enable at least one task permission (DynamoDB, SQS, SNS, SES, or STS) and provide corresponding ARNs."
    }
  }
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution-role"
  assume_role_policy = local.assume_role_policy
  tags               = var.tags
}

resource "aws_iam_policy" "execution_policy" {
  name   = "${var.name}-execution-policy"
  policy = local.execution_policy_document

  lifecycle {
    precondition {
      condition     = length(local.execution_policy_statements) > 0
      error_message = "Enable CloudWatch Logs or ECR pull (with repository ARNs) to create an execution policy."
    }
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.execution_policy.arn
}
