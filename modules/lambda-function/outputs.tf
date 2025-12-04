output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "function_qualified_arn" {
  description = "The ARN identifying your Lambda function version"
  value       = aws_lambda_function.this.qualified_arn
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "The ARN of the IAM role created for the Lambda function"
  value       = var.create_role ? aws_iam_role.lambda[0].arn : null
}

output "role_name" {
  description = "The name of the IAM role created for the Lambda function"
  value       = var.create_role ? aws_iam_role.lambda[0].name : null
}

output "alias_arn" {
  description = "The ARN of the Lambda alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].arn : null
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for the Lambda function"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].name : null
}
