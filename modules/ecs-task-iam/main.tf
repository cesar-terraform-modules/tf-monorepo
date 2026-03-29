locals {
  task_policy_statements = [
    for statement in [
      var.enable_dynamodb && length(var.dynamodb_table_arns) > 0 ? {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"]
        Resource = var.dynamodb_table_arns
      } : null,
      var.enable_sqs_send_receive && length(var.sqs_queue_arns) > 0 ? {
        Sid      = "SqsSendReceive"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ChangeMessageVisibility", "sqs:ListDeadLetterSourceQueues"]
        Resource = var.sqs_queue_arns
      } : null,
      var.enable_sns_publish && length(var.sns_topic_arns) > 0 ? {
        Sid      = "SnsPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arns
      } : null,
      var.enable_ses_send_email && length(var.ses_identity_arns) > 0 ? {
        Sid      = "SesSendEmail"
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail", "ses:SendTemplatedEmail", "ses:SendBulkTemplatedEmail"]
        Resource = var.ses_identity_arns
      } : null,
      var.enable_sts_assume_role && length(var.assumable_role_arns) > 0 ? {
        Sid      = "AssumeDelegatedRoles"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = var.assumable_role_arns
      } : null
    ] : statement if statement != null
  ]

  execution_policy_statements = [
    for statement in [
      var.enable_cloudwatch_logs && length(var.cloudwatch_log_group_arns) > 0 ? {
        Sid      = "CloudWatchLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = var.cloudwatch_log_group_arns
      } : null,
      var.enable_ecr_pull && length(var.ecr_repository_arns) > 0 ? {
        Sid      = "EcrGetAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      } : null,
      var.enable_ecr_pull && length(var.ecr_repository_arns) > 0 ? {
        Sid      = "EcrPullAccess"
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability", "ecr:DescribeImages", "ecr:DescribeRepositories"]
        Resource = var.ecr_repository_arns
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
