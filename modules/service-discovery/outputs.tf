output "namespace_id" {
  description = "The ID of the private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.this.id
}

output "namespace_arn" {
  description = "The ARN of the private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.this.arn
}

output "namespace_hosted_zone" {
  description = "The ID of the Route 53 hosted zone created for the namespace"
  value       = aws_service_discovery_private_dns_namespace.this.hosted_zone
}

output "service_arns" {
  description = "Map of service name to registry ARN, for use with ECS service_registries"
  value = {
    for name, svc in aws_service_discovery_service.this : name => svc.arn
  }
}
