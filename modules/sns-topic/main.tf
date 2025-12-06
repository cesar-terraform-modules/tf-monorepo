locals {
  subscriptions_input = [
    for s in var.subscriptions : {
      protocol             = try(s.protocol, "")
      endpoint             = try(s.endpoint, "")
      raw_message_delivery = try(s.raw_message_delivery, null)
      filter_policy_raw    = try(s.filter_policy, null)
      filter_policy        = try(s.filter_policy, null)
      delivery_policy      = try(s.delivery_policy, null)
    }
  ]

  subscriptions = {
    for idx, sub in local.subscriptions_input :
    idx => {
      protocol             = lower(sub.protocol)
      endpoint             = sub.endpoint
      raw_message_delivery = sub.raw_message_delivery
      filter_policy        = sub.filter_policy == null ? null : (length(try(sub.filter_policy, {})) == 0 ? null : sub.filter_policy)
      delivery_policy      = sub.delivery_policy
    }
  }
}

resource "aws_sns_topic" "this" {
  name         = var.topic_name
  display_name = var.fifo_topic ? null : var.display_name

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  kms_master_key_id = var.kms_master_key_id
  policy            = var.topic_policy
  delivery_policy   = var.delivery_policy

  tags = merge(
    var.tags,
    {
      Name = var.topic_name
    }
  )

  lifecycle {
    precondition {
      condition     = var.fifo_topic ? can(regex("\\.fifo$", var.topic_name)) : true
      error_message = "topic_name must end with .fifo when fifo_topic is true"
    }
  }
}

resource "aws_sns_topic_subscription" "this" {
  for_each = local.subscriptions

  topic_arn = aws_sns_topic.this.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  raw_message_delivery = each.value.raw_message_delivery
  filter_policy        = each.value.filter_policy != null ? jsonencode(each.value.filter_policy) : null
  delivery_policy      = each.value.delivery_policy
}
