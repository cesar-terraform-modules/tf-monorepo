variable "cluster_identifier" {
  description = "The cluster identifier. If omitted, Terraform will assign a random, unique identifier"
  type        = string
}

variable "engine" {
  description = "The name of the database engine to be used for this DB cluster"
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora", "aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "Engine must be one of: aurora, aurora-mysql, aurora-postgresql"
  }
}

variable "engine_version" {
  description = "The database engine version"
  type        = string
  default     = null
}

variable "database_name" {
  description = "Name for an automatically created database on cluster creation"
  type        = string
  default     = null
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
  default     = null
}

variable "backup_retention_period" {
  description = "The days to retain backups for. Default 7 days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days"
  }
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "If the DB cluster should have deletion protection enabled"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. When specifying kms_key_id, storage_encrypted needs to be set to true"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to cloudwatch. If omitted, no logs will be exported"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "vpc_id" {
  description = "ID of the VPC where to create the RDS cluster. If not provided, will be inferred from subnet_ids"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs to use for the DB subnet group. If not provided, will use data source to fetch subnets"
  type        = list(string)
  default     = null
}

variable "subnet_group_name" {
  description = "Name of the DB subnet group. If not provided, will create one"
  type        = string
  default     = null
}

variable "subnet_group_tags" {
  description = "Additional tags for the DB subnet group"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the cluster. If not provided, will create a security group"
  type        = list(string)
  default     = null
}

variable "create_security_group" {
  description = "Whether to create a security group for the RDS cluster"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group to create. If not provided, will use cluster identifier"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group for RDS cluster"
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS cluster"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access the RDS cluster"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = null
}

variable "db_cluster_instance_class" {
  description = "The instance class to use for the RDS cluster instances"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of cluster instances to create (including the primary). Minimum 1"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1"
  }
}

variable "read_replica_count" {
  description = "Number of read replicas to create. Can be 0 or more"
  type        = number
  default     = 0

  validation {
    condition     = var.read_replica_count >= 0
    error_message = "Read replica count must be 0 or greater"
  }
}

variable "max_read_replica_count" {
  description = "Maximum number of read replicas allowed. Used for validation"
  type        = number
  default     = 15

  validation {
    condition     = var.max_read_replica_count >= 0 && var.max_read_replica_count <= 15
    error_message = "Max read replica count must be between 0 and 15"
  }
}

variable "publicly_accessible" {
  description = "Whether the cluster instances are publicly accessible"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60"
  }
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be either 7 or 731 days"
  }
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB cluster is deleted"
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this cluster from a snapshot"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Cluster tags to snapshots"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "db_cluster_parameter_group_name" {
  description = "The name of the DB cluster parameter group to associate with this cluster"
  type        = string
  default     = null
}

variable "db_parameter_group_name" {
  description = "The name of the DB parameter group to associate with this cluster instances"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Enable to allow major engine version upgrades when changing engine versions"
  type        = bool
  default     = false
}

variable "serverlessv2_scaling_configuration" {
  description = "Nested attribute with scaling properties of an Aurora Serverless v2 DB cluster"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null
}

variable "subnet_filter" {
  description = "Map of filters to use when fetching subnets via data source. Used when subnet_ids is not provided"
  type = object({
    name   = string
    values = list(string)
  })
  default = null
}

