# Testing Guide

This document describes how to run tests for the Terraform modules in this repository.

## Overview

Each module in this repository includes comprehensive test suites using Terraform's native testing framework. Tests are organized into two categories:

- **Unit Tests** (`unit.tftest.hcl`) - Validate module configuration and resource definitions using `terraform plan`
- **Integration Tests** (`integration.tftest.hcl`) - Test complete module functionality with realistic configurations

## Prerequisites

You need either **Terraform >= 1.6.0** or **OpenTofu >= 1.6.0** installed to run these tests. The testing framework is compatible with both.

### Installing Terraform

Download from: https://www.terraform.io/downloads

```bash
# Verify installation
terraform version
```

### Installing OpenTofu

Download from: https://opentofu.org/docs/intro/install/

```bash
# Verify installation
tofu version
```

## Running Tests

### Test All Modules

To run all tests for all modules, use the following command from the repository root:

```bash
# Using Terraform
for module in modules/*/; do
  echo "Testing ${module}..."
  terraform -chdir="${module}" test
done

# Using OpenTofu
for module in modules/*/; do
  echo "Testing ${module}..."
  tofu -chdir="${module}" test
done
```

### Test a Specific Module

Navigate to the module directory and run the test command:

```bash
# Using Terraform
cd modules/s3-private-bucket
terraform test

# Using OpenTofu
cd modules/s3-private-bucket
tofu test
```

### Run Specific Test Files

To run only unit tests or integration tests:

```bash
# Run only unit tests
terraform test -filter=tests/unit.tftest.hcl

# Run only integration tests
terraform test -filter=tests/integration.tftest.hcl
```

### Run Specific Test Cases

To run a specific test case within a file:

```bash
# Run a specific test by name
terraform test -filter=tests/unit.tftest.hcl -run=test_basic_bucket_configuration
```

## Test Structure

Each module follows this test structure:

```
modules/
└── <module-name>/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── README.md
    └── tests/
        ├── unit.tftest.hcl        # Unit tests
        └── integration.tftest.hcl  # Integration tests
```

## Available Tests

### S3 Private Bucket Module

**Unit Tests** (`modules/s3-private-bucket/tests/unit.tftest.hcl`):
- Basic bucket configuration
- Versioning (enabled/disabled)
- Encryption (AES256/KMS)
- Lifecycle rules (expiration, transitions)
- Force destroy settings
- Tag application

**Integration Tests** (`modules/s3-private-bucket/tests/integration.tftest.hcl`):
- Complete bucket with all features
- Minimal bucket configuration
- KMS-encrypted bucket
- Lifecycle rules variations

### DynamoDB Global Table Module

**Unit Tests** (`modules/dynamodb-global-table/tests/unit.tftest.hcl`):
- Basic table configuration
- Provisioned vs. on-demand billing
- Hash key and range key
- Global secondary indexes
- Multi-region replication
- Encryption (default/KMS)
- Point-in-time recovery
- TTL configuration
- Tag application

**Integration Tests** (`modules/dynamodb-global-table/tests/integration.tftest.hcl`):
- Complete global table with all features
- Minimal table configuration
- Provisioned capacity with GSI
- Multi-region with KMS encryption

### Lambda Function Module

**Unit Tests** (`modules/lambda-function/tests/unit.tftest.hcl`):
- Basic function configuration
- Custom timeout and memory settings
- IAM role creation and external roles
- VPC configuration
- Environment variables
- Dead letter queue configuration
- X-Ray tracing
- Alias creation
- CloudWatch Logs
- S3 deployment source
- Additional IAM policies
- Reserved concurrency
- Tag application

**Integration Tests** (`modules/lambda-function/tests/integration.tftest.hcl`):
- Complete function with all features
- Minimal function configuration
- S3-based deployment
- Functions without log groups
- Functions without aliases
- External IAM role usage

### Fargate ECS Blue/Green Module

**Unit Tests** (`modules/fargate-ecs-bluegreen/tests/unit.tftest.hcl`):
- Basic ECS service configuration
- Custom CPU and memory settings
- Existing vs. new cluster
- Container Insights
- Execution and task role creation
- External IAM roles
- Service scaling
- Load balancer configuration
- Service discovery
- ECS Exec
- Blue/green deployment (enabled/disabled)
- Tag application

**Integration Tests** (`modules/fargate-ecs-bluegreen/tests/integration.tftest.hcl`):
- Complete Fargate service with all features
- Minimal service configuration
- Service on existing cluster
- EFS volume integration
- Service discovery integration
- Service without blue/green deployment
- Multi-container task definitions

## Test Output

When running tests, you'll see output like:

```
tests/unit.tftest.hcl... in progress
  run "test_basic_bucket_configuration"... pass
  run "test_versioning_enabled"... pass
  run "test_versioning_disabled"... pass
  run "test_default_encryption_aes256"... pass
tests/unit.tftest.hcl... pass

tests/integration.tftest.hcl... in progress
  run "integration_test_complete_bucket"... pass
  run "integration_test_minimal_bucket"... pass
tests/integration.tftest.hcl... pass

Success! 10 passed, 0 failed.
```

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Test Terraform Modules

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      
      - name: Run Tests
        run: |
          for module in modules/*/; do
            echo "Testing ${module}..."
            terraform -chdir="${module}" init
            terraform -chdir="${module}" test
          done
```

## Writing New Tests

When adding new features to modules, follow these guidelines:

1. **Add unit tests** to validate the configuration logic
2. **Add integration tests** for complete end-to-end scenarios
3. **Use descriptive test names** that explain what is being tested
4. **Include assertion messages** that clearly explain failures
5. **Test edge cases** and error conditions

### Example Test Structure

```hcl
run "test_feature_name" {
  command = plan

  variables {
    required_var = "value"
    optional_var = "custom_value"
  }

  assert {
    condition     = resource.attribute == expected_value
    error_message = "Descriptive message explaining what should happen"
  }
}
```

## Troubleshooting

### Test Failures

If a test fails, the output will show:
- Which test failed
- The assertion that failed
- The error message explaining why

Example:
```
run "test_basic_bucket_configuration"... fail
  Error: Test assertion failed
  
  on tests/unit.tftest.hcl line 15, in run "test_basic_bucket_configuration":
   15:     condition     = aws_s3_bucket.this.bucket == "test-bucket-12345"
      ├────────────────
      │ aws_s3_bucket.this.bucket is "wrong-bucket-name"
  
  Bucket name should match the input variable
```

### Common Issues

1. **AWS Provider not initialized**: Some tests may require AWS provider configuration. Ensure you have valid AWS credentials or use mocked providers.

2. **Missing dependencies**: Make sure to run `terraform init` in the module directory before running tests.

3. **Version mismatch**: Ensure you're using Terraform >= 1.6.0 or OpenTofu >= 1.6.0.

## Additional Resources

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [OpenTofu Testing Documentation](https://opentofu.org/docs/language/tests/)
- [Terraform Test Command Reference](https://developer.hashicorp.com/terraform/cli/commands/test)

## Contributing

When contributing new modules or features:

1. Write comprehensive unit tests for all configuration options
2. Write integration tests for common use cases
3. Ensure all tests pass before submitting a pull request
4. Update this documentation if you add new test patterns or conventions
