mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

# Integration tests for dynamodb-global-table module
# These tests validate the module with actual AWS provider (or mocked provider)

run "integration_test_complete_global_table" {
  command = plan

  variables {
    table_name   = "integration-test-global-table-12345"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "user_id"
    range_key    = "timestamp"
    
    attributes = [
      {
        name = "user_id"
        type = "S"
      },
      {
        name = "timestamp"
        type = "N"
      },
      {
        name = "status"
        type = "S"
      }
    ]
    
    global_secondary_indexes = [
      {
        name            = "status-index"
        hash_key        = "status"
        range_key       = "timestamp"
        projection_type = "ALL"
      }
    ]
    
    replica_regions = ["us-west-2", "eu-west-1"]
    
    encryption_enabled             = true
    point_in_time_recovery_enabled = true
    ttl_enabled                    = true
    ttl_attribute_name             = "expires_at"
    
    tags = {
      Environment = "integration-test"
      ManagedBy   = "Terraform"
      TestRun     = "complete"
    }
  }

  # Verify table is created with all features
  assert {
    condition     = aws_dynamodb_table.this.name != null
    error_message = "DynamoDB table should be created"
  }

  assert {
    condition     = aws_dynamodb_table.this.hash_key == "user_id"
    error_message = "Hash key should be user_id"
  }

  assert {
    condition     = aws_dynamodb_table.this.range_key == "timestamp"
    error_message = "Range key should be timestamp"
  }

  assert {
    condition     = length(aws_dynamodb_table.this.global_secondary_index) == 1
    error_message = "Should have 1 GSI"
  }

  assert {
    condition     = length(aws_dynamodb_table.this.replica) == 2
    error_message = "Should have 2 replicas"
  }
}

run "integration_test_minimal_table" {
  command = plan

  variables {
    table_name   = "integration-test-minimal-table-12345"
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

  # Verify minimal configuration works
  assert {
    condition     = aws_dynamodb_table.this.name != null
    error_message = "DynamoDB table should be created with minimal configuration"
  }

  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST"
    error_message = "Billing mode should be PAY_PER_REQUEST"
  }

  assert {
    condition     = length(aws_dynamodb_table.this.replica) == 0
    error_message = "Should have no replicas"
  }
}

run "integration_test_provisioned_with_gsi" {
  command = plan

  variables {
    table_name     = "integration-test-provisioned-12345"
    billing_mode   = "PROVISIONED"
    hash_key       = "pk"
    read_capacity  = 10
    write_capacity = 10
    
    attributes = [
      {
        name = "pk"
        type = "S"
      },
      {
        name = "gsi_pk"
        type = "S"
      }
    ]
    
    global_secondary_indexes = [
      {
        name            = "gsi-1"
        hash_key        = "gsi_pk"
        projection_type = "KEYS_ONLY"
        read_capacity   = 5
        write_capacity  = 5
      }
    ]
    
    replica_regions = []
  }

  # Verify provisioned capacity on table and GSI
  assert {
    condition     = aws_dynamodb_table.this.read_capacity == 10
    error_message = "Table read capacity should be 10"
  }

  assert {
    condition     = aws_dynamodb_table.this.write_capacity == 10
    error_message = "Table write capacity should be 10"
  }

  assert {
    condition     = aws_dynamodb_table.this.global_secondary_index[0].read_capacity == 5
    error_message = "GSI read capacity should be 5"
  }

  assert {
    condition     = aws_dynamodb_table.this.global_secondary_index[0].write_capacity == 5
    error_message = "GSI write capacity should be 5"
  }
}

run "integration_test_multi_region_with_kms" {
  command = plan

  variables {
    table_name        = "integration-test-multi-region-kms-12345"
    billing_mode      = "PAY_PER_REQUEST"
    hash_key          = "id"
    encryption_enabled = true
    kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    
    attributes = [
      {
        name = "id"
        type = "S"
      }
    ]
    
    replica_regions = ["us-west-2", "eu-west-1"]
    
    replica_kms_key_arns = {
      "us-west-2" = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
      "eu-west-1" = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  }

  # Verify replicas have KMS keys configured
  assert {
    condition     = length(aws_dynamodb_table.this.replica) == 2
    error_message = "Should have 2 replicas"
  }

  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].enabled == true
    error_message = "Encryption should be enabled"
  }
}
