# Data source to fetch subnets if subnet_ids is not provided
data "aws_subnets" "this" {
  count = var.subnet_ids == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  dynamic "filter" {
    for_each = var.subnet_filter != null ? [var.subnet_filter] : []
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# Data source to get subnet details for reuse
data "aws_subnet" "this" {
  for_each = toset(var.subnet_ids != null ? var.subnet_ids : data.aws_subnets.this[0].ids)

  id = each.value
}

locals {
  # Infer VPC ID from subnets if not provided
  # If subnet_ids are provided, get VPC ID from the first subnet
  # Otherwise, use the provided vpc_id (required when using subnet_filter)
  vpc_id = var.vpc_id != null ? var.vpc_id : (var.subnet_ids != null && length(var.subnet_ids) > 0 ? data.aws_subnet.this[var.subnet_ids[0]].vpc_id : null)

  # Use provided subnet IDs or fetch from data source
  subnet_ids_list = var.subnet_ids != null ? var.subnet_ids : data.aws_subnets.this[0].ids

  # Validate read replica count doesn't exceed maximum
  read_replica_count_validated = min(var.read_replica_count, var.max_read_replica_count)

  # Calculate total instances (primary + read replicas)
  total_instances = var.instance_count + local.read_replica_count_validated

  # Default port based on engine
  default_port = var.engine == "aurora-postgresql" ? 5432 : (var.engine == "aurora-mysql" ? 3306 : 3306)
  db_port      = var.port != null ? var.port : local.default_port

  # Security group name
  security_group_name = var.security_group_name != null ? var.security_group_name : "${var.cluster_identifier}-sg"

  # Subnet group name
  subnet_group_name = var.subnet_group_name != null ? var.subnet_group_name : "${var.cluster_identifier}-subnet-group"
}

# Data source to get VPC CIDR block
data "aws_vpc" "this" {
  id = local.vpc_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = local.subnet_group_name
  subnet_ids = local.subnet_ids_list

  tags = merge(
    var.tags,
    var.subnet_group_tags,
    {
      Name = local.subnet_group_name
    }
  )
}

# Security Group for RDS Cluster
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = local.security_group_name
  description = var.security_group_description
  vpc_id      = local.vpc_id

  tags = merge(
    var.tags,
    {
      Name = local.security_group_name
    }
  )
}

# Security Group Rules - Allow ingress from CIDR blocks
resource "aws_security_group_rule" "ingress_cidr" {
  for_each = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? toset(var.allowed_cidr_blocks) : []

  type              = "ingress"
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this[0].id
  description       = "Allow access from CIDR block ${each.value}"
}

# Security Group Rules - Allow ingress from other security groups
resource "aws_security_group_rule" "ingress_sg" {
  for_each = var.create_security_group && length(var.allowed_security_groups) > 0 ? toset(var.allowed_security_groups) : []

  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.this[0].id
  description              = "Allow access from security group ${each.value}"
}

# Security Group Rules - Egress (limit to VPC CIDR)
resource "aws_security_group_rule" "egress_vpc" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.this[0].id
  description       = "Allow outbound traffic to VPC CIDR"
}

locals {
  # Combine security groups - created one + provided ones
  security_group_ids = var.create_security_group ? concat([aws_security_group.this[0].id], var.security_group_ids != null ? var.security_group_ids : []) : (var.security_group_ids != null ? var.security_group_ids : [])
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  name_prefix = "${var.cluster_identifier}-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier              = var.cluster_identifier
  engine                          = var.engine
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  storage_encrypted               = var.storage_encrypted
  kms_key_id                      = var.kms_key_id
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = local.security_group_ids
  port                            = local.db_port
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  snapshot_identifier             = var.snapshot_identifier
  apply_immediately               = var.apply_immediately
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name
  allow_major_version_upgrade     = var.allow_major_version_upgrade

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration != null ? [var.serverlessv2_scaling_configuration] : []
    content {
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_identifier
    }
  )

  lifecycle {
    precondition {
      condition     = var.read_replica_count <= var.max_read_replica_count
      error_message = "Read replica count (${var.read_replica_count}) exceeds maximum allowed (${var.max_read_replica_count})"
    }

    precondition {
      condition     = length(local.subnet_ids_list) >= 2
      error_message = "At least 2 subnets are required for RDS cluster across multiple availability zones"
    }

    precondition {
      condition     = local.vpc_id != null
      error_message = "VPC ID must be provided either directly via vpc_id variable or inferred from subnet_ids. When using subnet_filter, vpc_id is required."
    }
  }
}

# RDS Cluster Instances (Primary + Read Replicas)
resource "aws_rds_cluster_instance" "this" {
  count = local.total_instances

  identifier                            = "${var.cluster_identifier}-${count.index}"
  cluster_identifier                    = aws_rds_cluster.this.id
  instance_class                        = var.db_cluster_instance_class
  engine                                = var.engine
  engine_version                        = var.engine_version
  publicly_accessible                   = var.publicly_accessible
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? (var.monitoring_role_arn != null ? var.monitoring_role_arn : aws_iam_role.enhanced_monitoring[0].arn) : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  db_parameter_group_name               = var.db_parameter_group_name
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  apply_immediately                     = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-${count.index}"
      Type = count.index < var.instance_count ? "primary" : "read-replica"
    }
  )
}

