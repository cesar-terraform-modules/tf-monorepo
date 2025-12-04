mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

# Integration tests for lambda-function module
# These tests validate the module with actual AWS provider (or mocked provider)

run "integration_test_complete_lambda" {
  command = plan

  variables {
    function_name = "integration-test-complete-12345"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    description   = "Integration test Lambda function"

    timeout     = 60
    memory_size = 512
    publish     = true

    environment_variables = {
      ENVIRONMENT = "integration-test"
      LOG_LEVEL   = "INFO"
    }

    vpc_config = {
      subnet_ids         = ["subnet-12345", "subnet-67890"]
      security_group_ids = ["sg-12345"]
    }

    dead_letter_target_arn         = "arn:aws:sqs:us-east-1:123456789012:test-dlq"
    tracing_mode                   = "Active"
    reserved_concurrent_executions = 5

    create_role = true
    additional_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    ]

    create_alias      = true
    alias_name        = "live"
    alias_description = "Live version"

    create_log_group   = true
    log_retention_days = 30

    tags = {
      Environment = "integration-test"
      ManagedBy   = "Terraform"
      TestRun     = "complete"
    }
  }

  # Verify all resources are created
  assert {
    condition     = aws_lambda_function.this.function_name != null
    error_message = "Lambda function should be created"
  }

  assert {
    condition     = length([for r in [aws_iam_role.lambda] : r if r != null]) > 0
    error_message = "IAM role should be created"
  }

  assert {
    condition     = length([for a in [aws_lambda_alias.this] : a if a != null]) > 0
    error_message = "Lambda alias should be created"
  }

  assert {
    condition     = length([for lg in [aws_cloudwatch_log_group.lambda] : lg if lg != null]) > 0
    error_message = "CloudWatch log group should be created"
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config) > 0
    error_message = "VPC configuration should be set"
  }
}

run "integration_test_minimal_lambda" {
  command = plan

  variables {
    function_name = "integration-test-minimal-12345"
    handler       = "index.handler"
    runtime       = "nodejs20.x"
    filename      = "/tmp/test-lambda.zip"
  }

  # Verify minimal configuration works
  assert {
    condition     = aws_lambda_function.this.function_name != null
    error_message = "Lambda function should be created with minimal configuration"
  }

  assert {
    condition     = aws_lambda_function.this.timeout == 3
    error_message = "Should use default timeout"
  }

  assert {
    condition     = aws_lambda_function.this.memory_size == 128
    error_message = "Should use default memory size"
  }

  assert {
    condition     = length([for r in [aws_iam_role.lambda] : r if r != null]) > 0
    error_message = "IAM role should be created by default"
  }
}

run "integration_test_s3_source" {
  command = plan

  variables {
    function_name     = "integration-test-s3-12345"
    handler           = "index.handler"
    runtime           = "python3.11"
    s3_bucket         = "my-lambda-functions"
    s3_key            = "functions/test-function.zip"
    s3_object_version = "v1.0.0"
  }

  # Verify S3 source configuration
  assert {
    condition     = aws_lambda_function.this.s3_bucket == "my-lambda-functions"
    error_message = "S3 bucket should be configured"
  }

  assert {
    condition     = aws_lambda_function.this.s3_key == "functions/test-function.zip"
    error_message = "S3 key should be configured"
  }

  assert {
    condition     = aws_lambda_function.this.filename == null
    error_message = "Filename should be null when using S3 source"
  }
}

run "integration_test_without_log_group" {
  command = plan

  variables {
    function_name    = "integration-test-no-logs-12345"
    handler          = "index.handler"
    runtime          = "python3.11"
    filename         = "/tmp/test-lambda.zip"
    create_log_group = false
  }

  # Verify log group is not created
  assert {
    condition     = length([for lg in [aws_cloudwatch_log_group.lambda] : lg if lg != null]) == 0
    error_message = "CloudWatch log group should not be created when create_log_group is false"
  }
}

run "integration_test_without_alias" {
  command = plan

  variables {
    function_name = "integration-test-no-alias-12345"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    create_alias  = false
  }

  # Verify alias is not created
  assert {
    condition     = length([for a in [aws_lambda_alias.this] : a if a != null]) == 0
    error_message = "Lambda alias should not be created when create_alias is false"
  }
}

run "integration_test_with_external_role" {
  command = plan

  variables {
    function_name   = "integration-test-external-role-12345"
    handler         = "index.handler"
    runtime         = "python3.11"
    filename        = "/tmp/test-lambda.zip"
    create_role     = false
    lambda_role_arn = "arn:aws:iam::123456789012:role/custom-lambda-role"
  }

  # Verify external role is used and no role is created
  assert {
    condition     = aws_lambda_function.this.role == "arn:aws:iam::123456789012:role/custom-lambda-role"
    error_message = "Should use external IAM role"
  }

  assert {
    condition     = length([for r in [aws_iam_role.lambda] : r if r != null]) == 0
    error_message = "IAM role should not be created when using external role"
  }
}
