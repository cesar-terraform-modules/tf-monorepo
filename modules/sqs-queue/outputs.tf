output "queue_id" {
  description = "The SQS queue ID."
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "The ARN of the SQS queue."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "The URL of the SQS queue."
  value       = aws_sqs_queue.this.url
}

output "dlq_arn" {
  description = "The ARN of the dead-letter queue when created."
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "The URL of the dead-letter queue when created."
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}
