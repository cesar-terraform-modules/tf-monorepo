# Integration tests for sns-topic module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_topic_with_http_and_sqs" {
  command = plan

  variables {
    topic_name = "retroboard-slack-alerts"
    subscriptions = [
      {
        protocol = "http"
        endpoint = "http://localhost:8080/alerts"
      },
      {
        protocol             = "sqs"
        endpoint             = "arn:aws:sqs:us-east-1:123456789012:retroboard-alerts-queue"
        raw_message_delivery = true
      }
    ]
    tags = {
      Environment = "integration"
      Service     = "retroboard"
    }
  }

  assert {
    condition     = aws_sns_topic.this.name == "retroboard-slack-alerts"
    error_message = "SNS topic should be created"
  }

  assert {
    condition     = aws_sns_topic.this.fifo_topic == false
    error_message = "Topic should be standard for this test"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.this) == 2
    error_message = "Both HTTP and SQS subscriptions should be created"
  }

  assert {
    condition     = contains([for s in aws_sns_topic_subscription.this : s.protocol], "http")
    error_message = "HTTP subscription should exist"
  }

  assert {
    condition     = contains([for s in aws_sns_topic_subscription.this : s.protocol], "sqs")
    error_message = "SQS subscription should exist"
  }
}

run "integration_fifo_topic_with_kms" {
  command = plan

  variables {
    topic_name                  = "retroboard-slack-alerts.fifo"
    fifo_topic                  = true
    content_based_deduplication = true
    kms_master_key_id           = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-5678-90ab-cdef-111122223333"
    delivery_policy             = "{\"healthyRetryPolicy\":{}}"
    tags = {
      Environment = "integration"
      Tier        = "fifo"
    }
  }

  assert {
    condition     = aws_sns_topic.this.fifo_topic == true
    error_message = "FIFO topic should be configured"
  }

  assert {
    condition     = aws_sns_topic.this.content_based_deduplication == true
    error_message = "Content-based deduplication should be enabled for FIFO"
  }

  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-5678-90ab-cdef-111122223333"
    error_message = "KMS key should be applied for encryption"
  }

  assert {
    condition     = aws_sns_topic.this.delivery_policy == "{\"healthyRetryPolicy\":{}}"
    error_message = "Delivery policy should be set on the topic"
  }
}
