output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "ID of the security group created for the ALB"
  value       = aws_security_group.this.id
}

output "target_group_arns" {
  description = "Map of target group name to ARN"
  value       = { for name, tg in aws_lb_target_group.this : name => tg.arn }
}

output "listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.http_default_action == "forward" ? aws_lb_listener.http_forward[0].arn : aws_lb_listener.http_redirect[0].arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (null if HTTPS is not enabled)"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "ecs_security_group_id" {
  description = "ID of the ECS task security group (null if not created)"
  value       = var.create_ecs_security_group ? aws_security_group.ecs_tasks[0].id : null
}
