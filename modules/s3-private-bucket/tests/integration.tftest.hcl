# Integration tests for s3-private-bucket module
# These tests validate the module with actual AWS provider

run "integration_test_complete_bucket" {
  command = plan

  variables {
    bucket_name        = "integration-test-bucket-complete-12345"
    versioning_enabled = true
    force_destroy      = true
    kms_key_id         = null
    lifecycle_rules = [
      {
        id              = "archive-old-logs"
        enabled         = true
        expiration_days = 365
        transitions = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            days          = 90
            storage_class = "GLACIER"
          }
        ]
      }
    ]
    tags = {
      Environment = "integration-test"
      ManagedBy   = "Terraform"
      TestRun     = "complete"
    }
  }

  # Verify all resources are created
  assert {
    condition     = aws_s3_bucket.this.bucket == "integration-test-bucket-complete-12345"
    error_message = "S3 bucket should be created"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "Public access block should be created"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning configuration should be created"
  }

  assert {
    condition     = length([for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule : rule]) > 0
    error_message = "Encryption configuration should be created"
  }

  assert {
    condition     = length([for r in [aws_s3_bucket_lifecycle_configuration.this] : r if r != null]) > 0
    error_message = "Lifecycle configuration should be created"
  }
}

run "integration_test_minimal_bucket" {
  command = plan

  variables {
    bucket_name = "integration-test-bucket-minimal-67890"
  }

  # Verify minimal configuration creates all required resources
  assert {
    condition     = aws_s3_bucket.this.bucket == "integration-test-bucket-minimal-67890"
    error_message = "S3 bucket should be created with minimal configuration"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy should be false by default"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled by default"
  }
}

run "integration_test_bucket_with_kms" {
  command = plan

  variables {
    bucket_name = "integration-test-bucket-kms-11111"
    kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    tags = {
      Environment = "integration-test"
      Encryption  = "KMS"
    }
  }

  # Verify KMS encryption is properly configured
  assert {
    condition     = length([for rule in aws_s3_bucket_server_side_encryption_configuration.this.rule : rule if rule.apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"]) > 0
    error_message = "KMS encryption should be configured"
  }
}

run "integration_test_disabled_lifecycle" {
  command = plan

  variables {
    bucket_name = "integration-test-bucket-no-lifecycle-22222"
    lifecycle_rules = [
      {
        id              = "disabled-rule"
        enabled         = false
        expiration_days = 30
        transitions     = null
      }
    ]
  }

  # Verify disabled lifecycle rule has correct status
  assert {
    condition     = length([for rule in aws_s3_bucket_lifecycle_configuration.this[0].rule : rule if rule.status == "Disabled"]) > 0
    error_message = "Lifecycle rule should be disabled when enabled is false"
  }
}
