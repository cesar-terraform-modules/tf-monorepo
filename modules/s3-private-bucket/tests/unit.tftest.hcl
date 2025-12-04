# Unit tests for s3-private-bucket module
# These tests validate the module configuration without creating actual resources

run "test_basic_bucket_configuration" {
  command = plan

  variables {
    bucket_name = "test-bucket-12345"
  }

  # Verify bucket is created with correct name
  assert {
    condition     = aws_s3_bucket.this.bucket == "test-bucket-12345"
    error_message = "Bucket name should match the input variable"
  }

  # Verify force_destroy defaults to false
  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy should default to false for safety"
  }

  # Verify public access block is configured correctly
  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_acls == true
    error_message = "Public ACLs should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.block_public_policy == true
    error_message = "Public policies should be blocked"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.ignore_public_acls == true
    error_message = "Public ACLs should be ignored"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets == true
    error_message = "Public buckets should be restricted"
  }
}

run "test_versioning_enabled" {
  command = plan

  variables {
    bucket_name        = "test-versioned-bucket"
    versioning_enabled = true
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled when versioning_enabled is true"
  }
}

run "test_versioning_disabled" {
  command = plan

  variables {
    bucket_name        = "test-unversioned-bucket"
    versioning_enabled = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Disabled"
    error_message = "Versioning should be disabled when versioning_enabled is false"
  }
}

run "test_default_encryption_aes256" {
  command = plan

  variables {
    bucket_name = "test-encrypted-bucket"
  }

  # Verify AES256 encryption is used when no KMS key is provided
  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Should use AES256 encryption by default"
  }

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].kms_master_key_id == null
    error_message = "KMS key ID should be null when not provided"
  }
}

run "test_kms_encryption" {
  command = plan

  variables {
    bucket_name = "test-kms-encrypted-bucket"
    kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  # Verify KMS encryption is used when KMS key is provided
  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Should use aws:kms encryption when KMS key is provided"
  }

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    error_message = "KMS key ID should match the provided value"
  }
}

run "test_lifecycle_rules_not_created_when_null" {
  command = plan

  variables {
    bucket_name     = "test-no-lifecycle-bucket"
    lifecycle_rules = null
  }

  # Verify lifecycle configuration is not created when lifecycle_rules is null
  assert {
    condition     = length([for r in [aws_s3_bucket_lifecycle_configuration.this] : r if r != null]) == 0
    error_message = "Lifecycle configuration should not be created when lifecycle_rules is null"
  }
}

run "test_lifecycle_rules_with_expiration" {
  command = plan

  variables {
    bucket_name = "test-lifecycle-bucket"
    lifecycle_rules = [
      {
        id              = "delete-old-objects"
        enabled         = true
        expiration_days = 90
        transitions     = null
      }
    ]
  }

  # Verify lifecycle rule is created with correct configuration
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].id == "delete-old-objects"
    error_message = "Lifecycle rule ID should match"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].status == "Enabled"
    error_message = "Lifecycle rule should be enabled"
  }
}

run "test_lifecycle_rules_with_transitions" {
  command = plan

  variables {
    bucket_name = "test-transition-bucket"
    lifecycle_rules = [
      {
        id              = "transition-to-glacier"
        enabled         = true
        expiration_days = null
        transitions = [
          {
            days          = 30
            storage_class = "GLACIER"
          },
          {
            days          = 90
            storage_class = "DEEP_ARCHIVE"
          }
        ]
      }
    ]
  }

  # Verify lifecycle rule has transitions
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition) == 2
    error_message = "Should have 2 transition rules"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[0].storage_class == "GLACIER"
    error_message = "First transition should be to GLACIER"
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this[0].rule[0].transition[1].storage_class == "DEEP_ARCHIVE"
    error_message = "Second transition should be to DEEP_ARCHIVE"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    bucket_name = "test-tagged-bucket"
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  # Verify tags are applied to bucket
  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Project"] == "testing"
    error_message = "Project tag should be applied"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Name"] == "test-tagged-bucket"
    error_message = "Name tag should be automatically added"
  }
}

run "test_force_destroy_enabled" {
  command = plan

  variables {
    bucket_name   = "test-force-destroy-bucket"
    force_destroy = true
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == true
    error_message = "force_destroy should be true when explicitly set"
  }
}
