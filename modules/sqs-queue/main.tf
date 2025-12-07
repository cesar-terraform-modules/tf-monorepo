data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  fifo_suffix = var.fifo_queue ? ".fifo" : ""
  base_name   = trimsuffix(var.queue_name, ".fifo")
  queue_name  = var.fifo_queue && !endswith(var.queue_name, ".fifo") ? "${var.queue_name}.fifo" : var.queue_name
  dlq_name    = var.enable_dlq ? (var.dlq_name != null ? (var.fifo_queue && !endswith(var.dlq_name, ".fifo") ? "${var.dlq_name}.fifo" : var.dlq_name) : "${local.base_name}-dlq${local.fifo_suffix}") : null
  dlq_arn     = var.enable_dlq ? format("arn:aws:sqs:%s:%s:%s", data.aws_region.current.id, data.aws_caller_identity.current.account_id, local.dlq_name) : null
}

resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  fifo_queue                  = var.fifo_queue
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  sqs_managed_sse_enabled     = var.kms_key_id == null ? true : null
  kms_master_key_id           = var.kms_key_id
  redrive_policy              = var.enable_dlq ? jsonencode({ deadLetterTargetArn = local.dlq_arn, maxReceiveCount = var.redrive_max_receive_count }) : null
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.fifo_queue || !endswith(local.queue_name, ".fifo")
      error_message = "Set fifo_queue to true when specifying a .fifo queue name."
    }
  }
}

resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name                       = local.dlq_name
  fifo_queue                 = var.fifo_queue
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.dlq_message_retention_seconds
  max_message_size           = var.max_message_size
  sqs_managed_sse_enabled    = var.kms_key_id == null ? true : null
  kms_master_key_id          = var.kms_key_id

  tags = var.tags
}

data "aws_iam_policy_document" "queue" {
  count = length(var.queue_policy_statements) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.queue_policy_statements
    content {
      sid     = try(statement.value.sid, null)
      effect  = coalesce(try(statement.value.effect, null), "Allow")
      actions = statement.value.actions
      resources = statement.value.resources != null ? statement.value.resources : [
        aws_sqs_queue.this.arn
      ]

      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : {}
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  count = length(var.queue_policy_statements) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.queue[0].json
}
