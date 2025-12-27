# Integration tests for rds-cluster module
# These tests validate the module configuration with mocked providers

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

run "test_cluster_deployment" {
  command = plan

  variables {
    cluster_identifier = "test-rds-cluster-integration"
    engine             = "aurora-postgresql"
    engine_version     = "15.4"
    database_name      = "testdb"
    master_username    = "admin"
    master_password    = "TestPassword123!ChangeMe"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]

    instance_count     = 1
    read_replica_count = 0

    # Security settings
    deletion_protection = false
    skip_final_snapshot = true

    tags = {
      Test        = "integration"
      Environment = "test"
    }
  }

  # Verify cluster configuration
  assert {
    condition     = aws_rds_cluster.this.cluster_identifier == "test-rds-cluster-integration"
    error_message = "Cluster identifier should match"
  }

  # Verify cluster endpoint would be available
  assert {
    condition     = aws_rds_cluster.this.database_name == "testdb"
    error_message = "Database name should be set"
  }

  # Verify at least one instance is created
  assert {
    condition     = length(aws_rds_cluster_instance.this) >= 1
    error_message = "At least one cluster instance should be created"
  }
}

run "test_cluster_with_read_replicas" {
  command = plan

  variables {
    cluster_identifier = "test-rds-cluster-replicas"
    engine             = "aurora-postgresql"
    engine_version     = "15.4"
    master_username    = "admin"
    master_password    = "TestPassword123!ChangeMe"
    vpc_id             = "vpc-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]

    instance_count     = 1
    read_replica_count = 2

    # Security settings
    deletion_protection = false
    skip_final_snapshot = true

    tags = {
      Test        = "integration"
      Environment = "test"
    }
  }

  # Verify cluster is configured
  assert {
    condition     = aws_rds_cluster.this.cluster_identifier == "test-rds-cluster-replicas"
    error_message = "Cluster identifier should match"
  }

  # Verify correct number of instances (1 primary + 2 replicas)
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 3
    error_message = "Should create 3 instances total (1 primary + 2 read replicas)"
  }
}

run "test_cluster_with_subnet_filter" {
  command = plan

  variables {
    cluster_identifier = "test-rds-cluster-filter"
    engine             = "aurora-postgresql"
    master_username    = "admin"
    master_password    = "TestPassword123!ChangeMe"
    vpc_id             = "vpc-12345678"
    subnet_ids         = null
    subnet_filter = {
      name   = "tag:Name"
      values = ["private-*"]
    }

    instance_count     = 1
    read_replica_count = 0

    deletion_protection = false
    skip_final_snapshot = true
  }

  # Verify subnet data source is used
  assert {
    condition     = length(data.aws_subnets.this) > 0
    error_message = "Subnet data source should be used when subnet_ids is null"
  }
}

