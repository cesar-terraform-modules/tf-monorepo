# Unit tests for dynamodb-global-table module
# These tests validate the module configuration without creating actual resources

run "test_basic_table_configuration" {
  command = plan

  variables {
    table_name   = "test-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify table is created with correct name
  assert {
    condition     = aws_dynamodb_table.this.name == "test-table"
    error_message = "Table name should match the input variable"
  }

  # Verify billing mode is set correctly
  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST"
    error_message = "Billing mode should be PAY_PER_REQUEST"
  }

  # Verify hash key is set correctly
  assert {
    condition     = aws_dynamodb_table.this.hash_key == "id"
    error_message = "Hash key should be 'id'"
  }

  # Verify stream is enabled for global tables
  assert {
    condition     = aws_dynamodb_table.this.stream_enabled == true
    error_message = "Stream should be enabled for global table support"
  }

  assert {
    condition     = aws_dynamodb_table.this.stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "Stream view type should be NEW_AND_OLD_IMAGES"
  }
}

run "test_provisioned_billing_mode" {
  command = plan

  variables {
    table_name     = "test-provisioned-table"
    billing_mode   = "PROVISIONED"
    hash_key       = "pk"
    read_capacity  = 5
    write_capacity = 5
    attributes = [
      {
        name = "pk"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify provisioned capacity is set
  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PROVISIONED"
    error_message = "Billing mode should be PROVISIONED"
  }

  assert {
    condition     = aws_dynamodb_table.this.read_capacity == 5
    error_message = "Read capacity should be 5"
  }

  assert {
    condition     = aws_dynamodb_table.this.write_capacity == 5
    error_message = "Write capacity should be 5"
  }
}

run "test_table_with_range_key" {
  command = plan

  variables {
    table_name   = "test-range-key-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "pk"
    range_key    = "sk"
    attributes = [
      {
        name = "pk"
        type = "S"
      },
      {
        name = "sk"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify range key is set
  assert {
    condition     = aws_dynamodb_table.this.hash_key == "pk"
    error_message = "Hash key should be 'pk'"
  }

  assert {
    condition     = aws_dynamodb_table.this.range_key == "sk"
    error_message = "Range key should be 'sk'"
  }
}

run "test_global_secondary_indexes" {
  command = plan

  variables {
    table_name   = "test-gsi-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"
    attributes = [
      {
        name = "id"
        type = "S"
      },
      {
        name = "status"
        type = "S"
      },
      {
        name = "created_at"
        type = "N"
      }
    ]
    global_secondary_indexes = [
      {
        name            = "status-index"
        hash_key        = "status"
        range_key       = "created_at"
        projection_type = "ALL"
      }
    ]
    replica_regions = []
  }

  # Verify GSI is created
  assert {
    condition     = length(aws_dynamodb_table.this.global_secondary_index) == 1
    error_message = "Should have 1 global secondary index"
  }

  assert {
    condition     = aws_dynamodb_table.this.global_secondary_index[0].name == "status-index"
    error_message = "GSI name should be 'status-index'"
  }

  assert {
    condition     = aws_dynamodb_table.this.global_secondary_index[0].hash_key == "status"
    error_message = "GSI hash key should be 'status'"
  }

  assert {
    condition     = aws_dynamodb_table.this.global_secondary_index[0].projection_type == "ALL"
    error_message = "GSI projection type should be 'ALL'"
  }
}

run "test_replica_regions" {
  command = plan

  variables {
    table_name   = "test-global-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = ["us-west-2", "eu-west-1"]
  }

  # Verify replicas are configured
  assert {
    condition     = length(aws_dynamodb_table.this.replica) == 2
    error_message = "Should have 2 replicas"
  }

  assert {
    condition     = contains([for r in aws_dynamodb_table.this.replica : r.region_name], "us-west-2")
    error_message = "Should have replica in us-west-2"
  }

  assert {
    condition     = contains([for r in aws_dynamodb_table.this.replica : r.region_name], "eu-west-1")
    error_message = "Should have replica in eu-west-1"
  }
}

run "test_encryption_enabled" {
  command = plan

  variables {
    table_name         = "test-encrypted-table"
    billing_mode       = "PAY_PER_REQUEST"
    hash_key           = "id"
    encryption_enabled = true
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify encryption is enabled
  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].enabled == true
    error_message = "Encryption should be enabled"
  }
}

run "test_encryption_with_kms" {
  command = plan

  variables {
    table_name         = "test-kms-encrypted-table"
    billing_mode       = "PAY_PER_REQUEST"
    hash_key           = "id"
    encryption_enabled = true
    kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify KMS encryption is configured
  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].enabled == true
    error_message = "Encryption should be enabled"
  }

  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "KMS key ARN should match"
  }
}

run "test_point_in_time_recovery" {
  command = plan

  variables {
    table_name                     = "test-pitr-table"
    billing_mode                   = "PAY_PER_REQUEST"
    hash_key                       = "id"
    point_in_time_recovery_enabled = true
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify PITR is enabled
  assert {
    condition     = aws_dynamodb_table.this.point_in_time_recovery[0].enabled == true
    error_message = "Point-in-time recovery should be enabled"
  }
}

run "test_ttl_configuration" {
  command = plan

  variables {
    table_name         = "test-ttl-table"
    billing_mode       = "PAY_PER_REQUEST"
    hash_key           = "id"
    ttl_enabled        = true
    ttl_attribute_name = "expires_at"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
  }

  # Verify TTL is configured
  assert {
    condition     = aws_dynamodb_table.this.ttl[0].enabled == true
    error_message = "TTL should be enabled"
  }

  assert {
    condition     = aws_dynamodb_table.this.ttl[0].attribute_name == "expires_at"
    error_message = "TTL attribute name should be 'expires_at'"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    table_name   = "test-tagged-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "id"
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    replica_regions = []
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  # Verify tags are applied
  assert {
    condition     = aws_dynamodb_table.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied"
  }

  assert {
    condition     = aws_dynamodb_table.this.tags["Project"] == "testing"
    error_message = "Project tag should be applied"
  }

  assert {
    condition     = aws_dynamodb_table.this.tags["Name"] == "test-tagged-table"
    error_message = "Name tag should be automatically added"
  }
}
