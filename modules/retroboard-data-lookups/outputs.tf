output "vpc_id" {
  description = "ID of the discovered VPC"
  value       = data.aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = data.aws_subnets.private.ids
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB boards table"
  value       = data.aws_dynamodb_table.boards.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = data.aws_sns_topic.alerts.arn
}

output "sqs_queue_arn" {
  description = "ARN of the SQS emails queue"
  value       = data.aws_sqs_queue.emails.arn
}

output "ses_identity_arn" {
  description = "ARN of the SES email identity"
  value       = data.aws_ses_email_identity.this.arn
}

output "ecr_repository_urls" {
  description = "Map of ECR repo name to repository URL"
  value       = { for name, repo in data.aws_ecr_repository.repos : name => repo.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of ECR repo name to repository ARN"
  value       = { for name, repo in data.aws_ecr_repository.repos : name => repo.arn }
}
