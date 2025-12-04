# Unit tests for lambda-function module
# These tests validate the module configuration without creating actual resources

run "test_basic_lambda_configuration" {
  command = plan

  variables {
    function_name = "test-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
  }

  # Verify function is created with correct configuration
  assert {
    condition     = aws_lambda_function.this.function_name == "test-function"
    error_message = "Function name should match the input variable"
  }

  assert {
    condition     = aws_lambda_function.this.handler == "index.handler"
    error_message = "Handler should match the input variable"
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.11"
    error_message = "Runtime should match the input variable"
  }

  # Verify defaults
  assert {
    condition     = aws_lambda_function.this.timeout == 3
    error_message = "Timeout should default to 3 seconds"
  }

  assert {
    condition     = aws_lambda_function.this.memory_size == 128
    error_message = "Memory size should default to 128 MB"
  }

  assert {
    condition     = aws_lambda_function.this.publish == false
    error_message = "Publish should default to false"
  }
}

run "test_lambda_with_custom_settings" {
  command = plan

  variables {
    function_name = "test-custom-function"
    handler       = "main.lambda_handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    description   = "Test Lambda function"
    timeout       = 30
    memory_size   = 512
    publish       = true
  }

  # Verify custom settings are applied
  assert {
    condition     = aws_lambda_function.this.timeout == 30
    error_message = "Timeout should be 30 seconds"
  }

  assert {
    condition     = aws_lambda_function.this.memory_size == 512
    error_message = "Memory size should be 512 MB"
  }

  assert {
    condition     = aws_lambda_function.this.publish == true
    error_message = "Publish should be true"
  }

  assert {
    condition     = aws_lambda_function.this.description == "Test Lambda function"
    error_message = "Description should match"
  }
}

run "test_iam_role_creation" {
  command = plan

  variables {
    function_name = "test-function-with-role"
    handler       = "index.handler"
    runtime       = "nodejs20.x"
    filename      = "/tmp/test-lambda.zip"
    create_role   = true
  }

  # Verify IAM role is created
  assert {
    condition     = length([for r in [aws_iam_role.lambda] : r if r != null]) > 0
    error_message = "IAM role should be created when create_role is true"
  }

  assert {
    condition     = aws_iam_role.lambda[0].name == "test-function-with-role-role"
    error_message = "IAM role name should follow naming convention"
  }

  # Verify basic execution role policy is attached
  assert {
    condition     = length([for a in [aws_iam_role_policy_attachment.lambda_basic] : a if a != null]) > 0
    error_message = "Basic execution role policy should be attached"
  }
}

run "test_external_iam_role" {
  command = plan

  variables {
    function_name   = "test-function-external-role"
    handler         = "index.handler"
    runtime         = "nodejs20.x"
    filename        = "/tmp/test-lambda.zip"
    create_role     = false
    lambda_role_arn = "arn:aws:iam::123456789012:role/external-lambda-role"
  }

  # Verify external role is used
  assert {
    condition     = aws_lambda_function.this.role == "arn:aws:iam::123456789012:role/external-lambda-role"
    error_message = "Should use external IAM role when create_role is false"
  }

  # Verify no IAM role is created
  assert {
    condition     = length([for r in [aws_iam_role.lambda] : r if r != null]) == 0
    error_message = "IAM role should not be created when create_role is false"
  }
}

run "test_vpc_configuration" {
  command = plan

  variables {
    function_name = "test-vpc-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    vpc_config = {
      subnet_ids         = ["subnet-12345", "subnet-67890"]
      security_group_ids = ["sg-12345"]
    }
  }

  # Verify VPC config is applied
  assert {
    condition     = length(aws_lambda_function.this.vpc_config) > 0
    error_message = "VPC configuration should be set"
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config[0].subnet_ids) == 2
    error_message = "Should have 2 subnet IDs"
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config[0].security_group_ids) == 1
    error_message = "Should have 1 security group ID"
  }

  # Verify VPC execution role policy is attached
  assert {
    condition     = length([for a in [aws_iam_role_policy_attachment.lambda_vpc] : a if a != null]) > 0
    error_message = "VPC execution role policy should be attached"
  }
}

run "test_environment_variables" {
  command = plan

  variables {
    function_name = "test-env-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    environment_variables = {
      ENV          = "production"
      DEBUG        = "false"
      API_ENDPOINT = "https://api.example.com"
    }
  }

  # Verify environment variables are set
  assert {
    condition     = aws_lambda_function.this.environment[0].variables["ENV"] == "production"
    error_message = "ENV variable should be set"
  }

  assert {
    condition     = aws_lambda_function.this.environment[0].variables["DEBUG"] == "false"
    error_message = "DEBUG variable should be set"
  }

  assert {
    condition     = aws_lambda_function.this.environment[0].variables["API_ENDPOINT"] == "https://api.example.com"
    error_message = "API_ENDPOINT variable should be set"
  }
}

run "test_dead_letter_config" {
  command = plan

  variables {
    function_name          = "test-dlq-function"
    handler                = "index.handler"
    runtime                = "python3.11"
    filename               = "/tmp/test-lambda.zip"
    dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789012:my-dlq"
  }

  # Verify dead letter queue is configured
  assert {
    condition     = length(aws_lambda_function.this.dead_letter_config) > 0
    error_message = "Dead letter config should be set"
  }

  assert {
    condition     = aws_lambda_function.this.dead_letter_config[0].target_arn == "arn:aws:sqs:us-east-1:123456789012:my-dlq"
    error_message = "Dead letter target ARN should match"
  }
}

run "test_xray_tracing" {
  command = plan

  variables {
    function_name = "test-tracing-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    tracing_mode  = "Active"
  }

  # Verify X-Ray tracing is configured
  assert {
    condition     = aws_lambda_function.this.tracing_config[0].mode == "Active"
    error_message = "Tracing mode should be Active"
  }
}

run "test_alias_creation" {
  command = plan

  variables {
    function_name     = "test-alias-function"
    handler           = "index.handler"
    runtime           = "python3.11"
    filename          = "/tmp/test-lambda.zip"
    create_alias      = true
    alias_name        = "production"
    alias_description = "Production alias"
  }

  # Verify alias is created
  assert {
    condition     = length([for a in [aws_lambda_alias.this] : a if a != null]) > 0
    error_message = "Lambda alias should be created when create_alias is true"
  }

  assert {
    condition     = aws_lambda_alias.this[0].name == "production"
    error_message = "Alias name should match"
  }

  assert {
    condition     = aws_lambda_alias.this[0].description == "Production alias"
    error_message = "Alias description should match"
  }
}

run "test_cloudwatch_log_group" {
  command = plan

  variables {
    function_name      = "test-log-function"
    handler            = "index.handler"
    runtime            = "python3.11"
    filename           = "/tmp/test-lambda.zip"
    create_log_group   = true
    log_retention_days = 14
  }

  # Verify CloudWatch log group is created
  assert {
    condition     = length([for lg in [aws_cloudwatch_log_group.lambda] : lg if lg != null]) > 0
    error_message = "CloudWatch log group should be created when create_log_group is true"
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda[0].name == "/aws/lambda/test-log-function"
    error_message = "Log group name should follow naming convention"
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda[0].retention_in_days == 14
    error_message = "Log retention should be 14 days"
  }
}

run "test_s3_deployment_source" {
  command = plan

  variables {
    function_name     = "test-s3-function"
    handler           = "index.handler"
    runtime           = "python3.11"
    s3_bucket         = "my-lambda-bucket"
    s3_key            = "lambda-functions/my-function.zip"
    s3_object_version = "abc123"
  }

  # Verify S3 source is configured
  assert {
    condition     = aws_lambda_function.this.s3_bucket == "my-lambda-bucket"
    error_message = "S3 bucket should be set"
  }

  assert {
    condition     = aws_lambda_function.this.s3_key == "lambda-functions/my-function.zip"
    error_message = "S3 key should be set"
  }

  assert {
    condition     = aws_lambda_function.this.s3_object_version == "abc123"
    error_message = "S3 object version should be set"
  }
}

run "test_additional_policy_arns" {
  command = plan

  variables {
    function_name = "test-additional-policies-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    additional_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
      "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
    ]
  }

  # Verify additional policies are attached
  assert {
    condition     = length(aws_iam_role_policy_attachment.additional_policies) == 2
    error_message = "Should have 2 additional policy attachments"
  }
}

run "test_reserved_concurrent_executions" {
  command = plan

  variables {
    function_name                  = "test-concurrency-function"
    handler                        = "index.handler"
    runtime                        = "python3.11"
    filename                       = "/tmp/test-lambda.zip"
    reserved_concurrent_executions = 10
  }

  # Verify reserved concurrency is set
  assert {
    condition     = aws_lambda_function.this.reserved_concurrent_executions == 10
    error_message = "Reserved concurrent executions should be 10"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    function_name = "test-tagged-function"
    handler       = "index.handler"
    runtime       = "python3.11"
    filename      = "/tmp/test-lambda.zip"
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  # Verify tags are applied
  assert {
    condition     = aws_lambda_function.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied"
  }

  assert {
    condition     = aws_lambda_function.this.tags["Project"] == "testing"
    error_message = "Project tag should be applied"
  }

  assert {
    condition     = aws_lambda_function.this.tags["Name"] == "test-tagged-function"
    error_message = "Name tag should be automatically added"
  }
}
