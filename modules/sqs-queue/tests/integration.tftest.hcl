# Integration tests for sqs-queue module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/mock"
      user_id    = "AIDAINVALID"
    }
  }
}

run "integration_standard_queue" {
  command = plan

  variables {
    queue_name                 = "retroboard-email-worker"
    visibility_timeout_seconds = 45
    message_retention_seconds  = 86400
    tags = {
      Service = "email"
      Env     = "test"
    }
  }

  assert {
    condition     = aws_sqs_queue.this.name == "retroboard-email-worker"
    error_message = "Standard queue should use the provided name."
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 0
    error_message = "DLQ should not be created when enable_dlq is false."
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true
    error_message = "Managed SSE should be enabled by default."
  }
}

run "integration_fifo_with_dlq_and_policy" {
  command = plan

  variables {
    queue_name                = "retroboard-email-worker-fifo"
    fifo_queue                = true
    enable_dlq                = true
    redrive_max_receive_count = 4
    kms_key_id                = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    queue_policy_statements = [
      {
        sid     = "AllowWorker"
        actions = ["sqs:SendMessage"]
        principals = [
          {
            type        = "AWS"
            identifiers = ["arn:aws:iam::123456789012:role/retroboard-worker"]
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
      Env     = "test"
      Tier    = "worker"
    }
  }

  assert {
    condition     = endswith(aws_sqs_queue.this.name, ".fifo")
    error_message = "FIFO queue should end with .fifo."
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].fifo_queue == true
    error_message = "DLQ should be FIFO when the main queue is FIFO."
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].name == "retroboard-email-worker-fifo-dlq.fifo"
    error_message = "DLQ should follow default naming with FIFO suffix."
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "KMS key should be set on the queue."
  }

  assert {
    condition     = length(aws_sqs_queue_policy.this) == 1
    error_message = "Queue policy should be attached."
  }
}
