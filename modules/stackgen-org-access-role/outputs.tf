output "stack_set_name" {
  description = "Name of the StackSet."
  value       = var.stack_set_name
}

output "stack_set_id" {
  description = "ID of the StackSet."
  value       = aws_cloudformation_stack_set.this.id
}

output "role_name" {
  description = "Name of the IAM role created in each target account."
  value       = var.role_name
}

output "role_arn_format" {
  description = "Role ARN format for target accounts; replace ACCOUNT_ID with the account number."
  value       = "arn:aws:iam::ACCOUNT_ID:role/${var.role_name}"
}

output "deployment_target_ou_ids" {
  description = "Organizational unit IDs targeted by the StackSet instance."
  value       = var.organizational_unit_ids
}
