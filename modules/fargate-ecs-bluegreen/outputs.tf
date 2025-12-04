output "cluster_id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].id : null
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].arn : null
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name
}

output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both family and revision)"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "The family of the Task Definition"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "The revision of the task in a particular family"
  value       = aws_ecs_task_definition.this.revision
}

output "service_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "The name of the service"
  value       = aws_ecs_service.this.name
}

output "execution_role_arn" {
  description = "The ARN of the task execution role"
  value       = var.create_execution_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
}

output "task_role_arn" {
  description = "The ARN of the task role"
  value       = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy application"
  value       = var.enable_blue_green_deployment ? aws_codedeploy_app.this[0].name : null
}

output "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value       = var.enable_blue_green_deployment ? aws_codedeploy_deployment_group.this[0].deployment_group_name : null
}

output "codedeploy_role_arn" {
  description = "The ARN of the CodeDeploy IAM role"
  value       = var.enable_blue_green_deployment && var.create_codedeploy_role ? aws_iam_role.codedeploy[0].arn : null
}
