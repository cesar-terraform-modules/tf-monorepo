# Unit tests for rds-cluster module
# These tests validate the module configuration without creating actual resources

mock_provider "aws" {
  mock_data "aws_subnets" {
    defaults = {
      ids = ["subnet-12345678", "subnet-87654321", "subnet-11223344"]
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      id                = "subnet-12345678"
      vpc_id            = "vpc-12345678"
      availability_zone = "us-east-1a"
      cidr_block        = "10.0.1.0/24"
    }
  }
}

run "test_basic_cluster_configuration" {
  command = plan

  variables {
    cluster_identifier = "test-cluster"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  }

  # Verify cluster is created with correct identifier
  assert {
    condition     = aws_rds_cluster.this.cluster_identifier == "test-cluster"
    error_message = "Cluster identifier should match the input variable"
  }

  # Verify encryption is enabled by default
  assert {
    condition     = aws_rds_cluster.this.storage_encrypted == true
    error_message = "Storage encryption should be enabled by default"
  }

  # Verify deletion protection is enabled by default
  assert {
    condition     = aws_rds_cluster.this.deletion_protection == true
    error_message = "Deletion protection should be enabled by default"
  }

  # Verify security group is created by default
  assert {
    condition     = length(aws_security_group.this) == 1
    error_message = "Security group should be created by default"
  }
}

run "test_read_replica_count_zero" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-no-replicas"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    read_replica_count = 0
    instance_count     = 1
  }

  # Verify only one instance is created (primary, no replicas)
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 1
    error_message = "Should create only one instance when read_replica_count is 0"
  }
}

run "test_read_replica_count_multiple" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-with-replicas"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    read_replica_count = 3
    instance_count     = 2
  }

  # Verify total instances = instance_count + read_replica_count
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 5
    error_message = "Should create 5 instances total (2 primary + 3 read replicas)"
  }
}

run "test_max_read_replica_validation" {
  command = plan

  variables {
    cluster_identifier     = "test-cluster-max-replicas"
    master_username        = "admin"
    master_password        = "TestPassword123!"
    vpc_id                 = "vpc-12345678"
    subnet_ids             = ["subnet-12345678", "subnet-87654321"]
    read_replica_count     = 10
    max_read_replica_count = 5
  }

  # Verify that read_replica_count is capped at max_read_replica_count
  # This should pass validation but actual count should be limited
  assert {
    condition     = length(aws_rds_cluster_instance.this) <= 6 # 1 primary + 5 max replicas
    error_message = "Read replica count should not exceed max_read_replica_count"
  }
}

run "test_subnet_data_source_exposure" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-subnets"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321", "subnet-11223344"]
  }

  # Verify subnet data sources are created
  assert {
    condition     = length(data.aws_subnet.this) == 3
    error_message = "Should create data sources for all provided subnets"
  }
}

run "test_security_group_creation_disabled" {
  command = plan

  variables {
    cluster_identifier    = "test-cluster-no-sg"
    master_username       = "admin"
    master_password       = "TestPassword123!"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-12345678", "subnet-87654321"]
    create_security_group = false
    security_group_ids    = ["sg-existing123"]
  }

  # Verify security group is not created
  assert {
    condition     = length(aws_security_group.this) == 0
    error_message = "Security group should not be created when create_security_group is false"
  }
}

run "test_security_group_ingress_rules" {
  command = plan

  variables {
    cluster_identifier      = "test-cluster-sg-rules"
    master_username         = "admin"
    master_password         = "TestPassword123!"
    vpc_id                  = "vpc-12345678"
    subnet_ids              = ["subnet-12345678", "subnet-87654321"]
    allowed_cidr_blocks     = ["10.0.0.0/16", "192.168.0.0/16"]
    allowed_security_groups = ["sg-12345678"]
  }

  # Verify ingress rules are created
  assert {
    condition     = length(aws_security_group_rule.ingress_cidr) == 2
    error_message = "Should create ingress rules for each CIDR block"
  }

  assert {
    condition     = length(aws_security_group_rule.ingress_sg) == 1
    error_message = "Should create ingress rule for security group"
  }
}

run "test_encryption_with_kms" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-kms"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    storage_encrypted  = true
    kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  # Verify KMS encryption is configured
  assert {
    condition     = aws_rds_cluster.this.storage_encrypted == true
    error_message = "Storage encryption should be enabled"
  }

  assert {
    condition     = aws_rds_cluster.this.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "KMS key ID should match the provided value"
  }
}

run "test_enhanced_monitoring" {
  command = plan

  variables {
    cluster_identifier  = "test-cluster-monitoring"
    master_username     = "admin"
    master_password     = "TestPassword123!"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    monitoring_interval = 60
  }

  # Verify monitoring role is created
  assert {
    condition     = length(aws_iam_role.enhanced_monitoring) == 1
    error_message = "Enhanced monitoring role should be created when monitoring_interval > 0"
  }

  # Verify monitoring is configured on instances
  assert {
    condition     = aws_rds_cluster_instance.this[0].monitoring_interval == 60
    error_message = "Monitoring interval should be set on cluster instances"
  }
}

run "test_performance_insights" {
  command = plan

  variables {
    cluster_identifier                    = "test-cluster-pi"
    master_username                       = "admin"
    master_password                       = "TestPassword123!"
    vpc_id                                = "vpc-12345678"
    subnet_ids                            = ["subnet-12345678", "subnet-87654321"]
    performance_insights_enabled          = true
    performance_insights_retention_period = 7
  }

  # Verify Performance Insights is enabled
  assert {
    condition     = aws_rds_cluster_instance.this[0].performance_insights_enabled == true
    error_message = "Performance Insights should be enabled"
  }

  assert {
    condition     = aws_rds_cluster_instance.this[0].performance_insights_retention_period == 7
    error_message = "Performance Insights retention period should be set"
  }
}

run "test_backup_configuration" {
  command = plan

  variables {
    cluster_identifier      = "test-cluster-backup"
    master_username         = "admin"
    master_password         = "TestPassword123!"
    vpc_id                  = "vpc-12345678"
    subnet_ids              = ["subnet-12345678", "subnet-87654321"]
    backup_retention_period = 14
    preferred_backup_window = "02:00-03:00"
  }

  # Verify backup configuration
  assert {
    condition     = aws_rds_cluster.this.backup_retention_period == 14
    error_message = "Backup retention period should match the provided value"
  }

  assert {
    condition     = aws_rds_cluster.this.preferred_backup_window == "02:00-03:00"
    error_message = "Preferred backup window should match the provided value"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-tags"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  # Verify tags are applied to cluster
  assert {
    condition     = aws_rds_cluster.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied to cluster"
  }

  assert {
    condition     = aws_rds_cluster.this.tags["Project"] == "testing"
    error_message = "Project tag should be applied to cluster"
  }

  assert {
    condition     = aws_rds_cluster.this.tags["Name"] == "test-cluster-tags"
    error_message = "Name tag should be automatically added"
  }
}

run "test_publicly_accessible_false" {
  command = plan

  variables {
    cluster_identifier  = "test-cluster-private"
    master_username     = "admin"
    master_password     = "TestPassword123!"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    publicly_accessible = false
  }

  # Verify instances are not publicly accessible
  assert {
    condition     = aws_rds_cluster_instance.this[0].publicly_accessible == false
    error_message = "Instances should not be publicly accessible by default"
  }
}

run "test_engine_version" {
  command = plan

  variables {
    cluster_identifier = "test-cluster-engine"
    engine             = "aurora-postgresql"
    engine_version     = "15.4"
    master_username    = "admin"
    master_password    = "TestPassword123!"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
  }

  # Verify engine and version
  assert {
    condition     = aws_rds_cluster.this.engine == "aurora-postgresql"
    error_message = "Engine should match the provided value"
  }

  assert {
    condition     = aws_rds_cluster.this.engine_version == "15.4"
    error_message = "Engine version should match the provided value"
  }
}

