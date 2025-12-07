# Unit tests for sqs-queue module

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

run "test_standard_defaults" {
  command = plan

  variables {
    queue_name = "standard-worker-queue"
  }

  assert {
    condition     = aws_sqs_queue.this.fifo_queue == false
    error_message = "Queue should be standard by default."
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true
    error_message = "Managed SSE should be enabled by default."
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == null
    error_message = "KMS key should be null when not provided."
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 0
    error_message = "DLQ should not be created when enable_dlq is false."
  }
}

run "test_fifo_queue_appends_suffix" {
  command = plan

  variables {
    queue_name = "fifo-worker"
    fifo_queue = true
    enable_dlq = true
    tags       = { Service = "email" }
    dlq_name   = "fifo-worker-deadletter"
    queue_policy_statements = [
      {
        actions = ["sqs:SendMessage"]
        principals = [
          {
            type        = "Service"
            identifiers = ["ses.amazonaws.com"]
          }
        ]
      }
    ]
  }

  assert {
    condition     = endswith(aws_sqs_queue.this.name, ".fifo")
    error_message = "FIFO queues should end with .fifo suffix."
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].fifo_queue == true
    error_message = "DLQ should also be FIFO when main queue is FIFO."
  }

  assert {
    condition     = length(aws_sqs_queue_policy.this) == 1
    error_message = "Queue policy should be attached when statements are provided."
  }
}

run "test_dlq_redrive_policy" {
  command = plan

  variables {
    queue_name                = "standard-worker"
    enable_dlq                = true
    redrive_max_receive_count = 3
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 1
    error_message = "DLQ should be created when enable_dlq is true."
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].name == "standard-worker-dlq"
    error_message = "DLQ should use the default naming convention."
  }
}

run "test_kms_encryption" {
  command = plan

  variables {
    queue_name = "kms-encrypted-queue"
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "Queue should use the provided KMS key."
  }
}

run "test_retention_and_visibility_limits" {
  command = plan

  variables {
    queue_name                 = "custom-timeouts"
    visibility_timeout_seconds = 60
    message_retention_seconds  = 600
    max_message_size           = 4096
  }

  assert {
    condition     = aws_sqs_queue.this.visibility_timeout_seconds == 60
    error_message = "Visibility timeout should match input."
  }

  assert {
    condition     = aws_sqs_queue.this.message_retention_seconds == 600
    error_message = "Message retention should match input."
  }

  assert {
    condition     = aws_sqs_queue.this.max_message_size == 4096
    error_message = "Max message size should match input."
  }
}
