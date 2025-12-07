output "task_role_arn" {
  description = "ARN of the IAM task role"
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role"
  value       = aws_iam_role.execution.arn
}

output "policy_arns" {
  description = "ARNs of the IAM policies created by the module (task, execution)"
  value = [
    aws_iam_policy.task_policy.arn,
    aws_iam_policy.execution_policy.arn
  ]
}
