# Lambda Function Module

This module creates an AWS Lambda function with optional IAM role, CloudWatch log group, and alias support.

## Features

- **Flexible deployment**: Support for both local file and S3-based deployments
- **IAM role management**: Automatically create and configure IAM role with proper permissions
- **VPC support**: Optional VPC configuration for private resource access
- **CloudWatch Logs**: Automatic log group creation with configurable retention
- **X-Ray tracing**: Optional AWS X-Ray integration
- **Dead letter queue**: Configure DLQ for failed invocations
- **Function aliases**: Support for Lambda function aliases
- **Environment variables**: Easy configuration of environment variables

## Usage

### Basic Lambda function with local deployment

```hcl
module "hello_world_lambda" {
  source = "./modules/lambda-function"

  function_name = "hello-world"
  description   = "Hello World Lambda function"
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "lambda_function.zip"
  
  timeout     = 30
  memory_size = 256

  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Lambda function with S3 deployment and VPC

```hcl
module "vpc_lambda" {
  source = "./modules/lambda-function"

  function_name = "vpc-lambda"
  description   = "Lambda function running in VPC"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  
  s3_bucket = "my-lambda-deployments"
  s3_key    = "lambda-packages/my-function.zip"
  
  timeout     = 60
  memory_size = 512

  vpc_config = {
    subnet_ids         = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-12345"]
  }

  environment_variables = {
    DB_HOST = "database.internal.example.com"
    DB_PORT = "5432"
  }

  tracing_mode = "Active"

  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Lambda function with alias

```hcl
module "lambda_with_alias" {
  source = "./modules/lambda-function"

  function_name = "my-function"
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "function.zip"
  
  publish = true

  create_alias          = true
  alias_name            = "production"
  alias_description     = "Production alias"
  alias_function_version = "1"

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| function_name | The name of the Lambda function | `string` | n/a | yes |
| handler | The function entrypoint in your code | `string` | n/a | yes |
| runtime | The runtime environment for the Lambda function | `string` | n/a | yes |
| description | Description of the Lambda function | `string` | `""` | no |
| timeout | The amount of time your Lambda function has to run in seconds | `number` | `3` | no |
| memory_size | Amount of memory in MB your Lambda function can use | `number` | `128` | no |
| filename | The path to the function's deployment package | `string` | `null` | no |
| s3_bucket | The S3 bucket location containing the function's deployment package | `string` | `null` | no |
| s3_key | The S3 key of an object containing the function's deployment package | `string` | `null` | no |
| s3_object_version | The object version containing the function's deployment package | `string` | `null` | no |
| publish | Whether to publish creation/change as new Lambda function version | `bool` | `false` | no |
| reserved_concurrent_executions | The amount of reserved concurrent executions | `number` | `-1` | no |
| environment_variables | A map of environment variables to pass to the Lambda function | `map(string)` | `{}` | no |
| vpc_config | VPC configuration for the Lambda function | `object` | `null` | no |
| dead_letter_target_arn | The ARN of an SNS topic or SQS queue for failed invocations | `string` | `null` | no |
| tracing_mode | AWS X-Ray tracing mode. Valid values: PassThrough, Active | `string` | `"PassThrough"` | no |
| create_role | Whether to create an IAM role for the Lambda function | `bool` | `true` | no |
| lambda_role_arn | IAM role ARN attached to the Lambda function | `string` | `null` | no |
| additional_policy_arns | List of additional IAM policy ARNs to attach | `list(string)` | `[]` | no |
| create_alias | Whether to create an alias for the Lambda function | `bool` | `false` | no |
| alias_name | Name for the alias | `string` | `"live"` | no |
| alias_description | Description of the alias | `string` | `""` | no |
| alias_function_version | Lambda function version for which you are creating the alias | `string` | `null` | no |
| create_log_group | Whether to create a CloudWatch log group | `bool` | `true` | no |
| log_retention_days | Number of days to retain Lambda function logs | `number` | `7` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | The ARN of the Lambda function |
| function_name | The name of the Lambda function |
| function_version | Latest published version of the Lambda function |
| function_qualified_arn | The ARN identifying your Lambda function version |
| invoke_arn | The ARN to be used for invoking Lambda function from API Gateway |
| role_arn | The ARN of the IAM role created for the Lambda function |
| role_name | The name of the IAM role created for the Lambda function |
| alias_arn | The ARN of the Lambda alias |
| log_group_name | The name of the CloudWatch log group |
