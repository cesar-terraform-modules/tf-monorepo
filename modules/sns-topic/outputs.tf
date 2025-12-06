output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.this.name
}

output "subscription_arns" {
  description = "List of ARNs for subscriptions created by this module"
  value       = [for s in aws_sns_topic_subscription.this : s.arn]
}
