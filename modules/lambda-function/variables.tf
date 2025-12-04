variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "The function entrypoint in your code"
  type        = string
}

variable "runtime" {
  description = "The runtime environment for the Lambda function"
  type        = string
}

variable "timeout" {
  description = "The amount of time your Lambda function has to run in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = number
  default     = 128
}

variable "filename" {
  description = "The path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "The S3 bucket location containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "The S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "The object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "publish" {
  description = "Whether to publish creation/change as new Lambda function version"
  type        = bool
  default     = false
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "A map of environment variables to pass to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_target_arn" {
  description = "The ARN of an SNS topic or SQS queue to notify when an invocation fails"
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "Whether to sample and trace a subset of incoming requests with AWS X-Ray. Valid values: PassThrough, Active"
  type        = string
  default     = "PassThrough"
}

variable "create_role" {
  description = "Whether to create an IAM role for the Lambda function"
  type        = bool
  default     = true
}

variable "lambda_role_arn" {
  description = "IAM role ARN attached to the Lambda function. Required if create_role is false"
  type        = string
  default     = null
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "create_alias" {
  description = "Whether to create an alias for the Lambda function"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name for the alias"
  type        = string
  default     = "live"
}

variable "alias_description" {
  description = "Description of the alias"
  type        = string
  default     = ""
}

variable "alias_function_version" {
  description = "Lambda function version for which you are creating the alias. If not specified, uses $LATEST"
  type        = string
  default     = null
}

variable "create_log_group" {
  description = "Whether to create a CloudWatch log group for the Lambda function"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda function logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
