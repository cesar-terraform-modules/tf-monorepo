# Unit tests for sns-topic module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "test_standard_topic_defaults" {
  command = plan

  variables {
    topic_name = "retroboard-alerts"
    tags = {
      Environment = "test"
    }
  }

  assert {
    condition     = aws_sns_topic.this.name == "retroboard-alerts"
    error_message = "Topic name should match input"
  }

  assert {
    condition     = aws_sns_topic.this.fifo_topic == false
    error_message = "Topic should default to standard (fifo_topic=false)"
  }

  assert {
    condition     = aws_sns_topic.this.display_name == null
    error_message = "Display name should be null by default"
  }

  assert {
    condition     = aws_sns_topic.this.tags["Name"] == "retroboard-alerts"
    error_message = "Name tag should be applied automatically"
  }
}

run "test_fifo_topic_with_dedup" {
  command = plan

  variables {
    topic_name                  = "retroboard-alerts.fifo"
    fifo_topic                  = true
    content_based_deduplication = true
    display_name                = "ignored-for-fifo"
  }

  assert {
    condition     = aws_sns_topic.this.fifo_topic == true
    error_message = "FIFO topic should set fifo_topic to true"
  }

  assert {
    condition     = aws_sns_topic.this.content_based_deduplication == true
    error_message = "Content-based deduplication should be enabled for FIFO"
  }

  assert {
    condition     = aws_sns_topic.this.display_name == null
    error_message = "Display name must be unset for FIFO topics"
  }
}

run "test_creates_subscriptions" {
  command = plan

  variables {
    topic_name = "retroboard-alerts"
    subscriptions = [
      {
        protocol             = "https"
        endpoint             = "https://alerts.example.com/slack"
        raw_message_delivery = false
        filter_policy        = null
        delivery_policy      = null
      },
      {
        protocol             = "sqs"
        endpoint             = "arn:aws:sqs:us-east-1:123456789012:retroboard-alerts-queue"
        raw_message_delivery = true
        filter_policy = {
          severity = ["critical"]
        }
        delivery_policy = null
      }
    ]
  }

  assert {
    condition     = length(aws_sns_topic_subscription.this) == 2
    error_message = "Two subscriptions should be created"
  }

  assert {
    condition     = contains([for s in aws_sns_topic_subscription.this : s.protocol], "https")
    error_message = "HTTPS subscription should be present"
  }

  assert {
    condition     = contains([for s in aws_sns_topic_subscription.this : s.protocol], "sqs")
    error_message = "SQS subscription should be present"
  }

  assert {
    condition     = anytrue([for s in aws_sns_topic_subscription.this : can(regex("severity", s.filter_policy))])
    error_message = "Filter policy should be applied to at least one subscription"
  }
}

run "test_kms_and_policies" {
  command = plan

  variables {
    topic_name        = "retroboard-kms-topic"
    kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-5678-90ab-cdef-111122223333"
    topic_policy      = "{\"Statement\":[]}"
    delivery_policy   = "{\"healthyRetryPolicy\":{}}"
  }

  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-5678-90ab-cdef-111122223333"
    error_message = "KMS key should be applied to the topic"
  }

  assert {
    condition     = aws_sns_topic.this.policy == "{\"Statement\":[]}"
    error_message = "Topic policy should be set when provided"
  }

  assert {
    condition     = aws_sns_topic.this.delivery_policy == "{\"healthyRetryPolicy\":{}}"
    error_message = "Delivery policy should be set when provided"
  }
}
