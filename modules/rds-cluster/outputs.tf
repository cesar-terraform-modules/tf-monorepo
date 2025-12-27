# Subnet Data Sources - Exposed for reuse
output "subnets" {
  description = "Map of subnet details fetched via data source, keyed by subnet ID"
  value       = data.aws_subnet.this
}

output "subnet_ids" {
  description = "List of subnet IDs used by the RDS cluster"
  value       = local.subnet_ids_list
}

output "subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.this.id
}

output "subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.this.arn
}

# Security Group Outputs
output "security_group_id" {
  description = "The ID of the security group created for the RDS cluster"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "The ARN of the security group created for the RDS cluster"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

output "security_group_ids" {
  description = "List of all security group IDs associated with the cluster"
  value       = local.security_group_ids
}

# RDS Cluster Outputs
output "cluster_id" {
  description = "The RDS Cluster Identifier"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of cluster"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The RDS Cluster Endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "The RDS Cluster Reader Endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_hosted_zone_id" {
  description = "The Route53 Hosted Zone ID of the endpoint"
  value       = aws_rds_cluster.this.hosted_zone_id
}

output "cluster_resource_id" {
  description = "The RDS Cluster Resource ID"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = aws_rds_cluster.this.database_name
}

output "cluster_port" {
  description = "The database port"
  value       = aws_rds_cluster.this.port
}

output "cluster_master_username" {
  description = "The master username for the database"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

# RDS Cluster Instance Outputs
output "cluster_instance_ids" {
  description = "List of RDS cluster instance identifiers"
  value       = aws_rds_cluster_instance.this[*].id
}

output "cluster_instance_arns" {
  description = "List of ARNs of the RDS cluster instances"
  value       = aws_rds_cluster_instance.this[*].arn
}

output "cluster_instance_endpoints" {
  description = "List of RDS cluster instance endpoints"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "primary_instance_id" {
  description = "ID of the primary cluster instance"
  value       = length(aws_rds_cluster_instance.this) > 0 ? aws_rds_cluster_instance.this[0].id : null
}

output "read_replica_instance_ids" {
  description = "List of read replica instance IDs"
  value       = slice(aws_rds_cluster_instance.this[*].id, var.instance_count, local.total_instances)
}

output "read_replica_count" {
  description = "Number of read replicas created"
  value       = local.read_replica_count_validated
}

# Monitoring Outputs
output "monitoring_role_arn" {
  description = "The ARN of the IAM role for enhanced monitoring"
  value       = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? aws_iam_role.enhanced_monitoring[0].arn : var.monitoring_role_arn
}

