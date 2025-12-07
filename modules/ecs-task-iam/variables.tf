variable "name" {
  description = "Base name used for IAM roles and policies created by this module"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty"
  }
}

variable "enable_dynamodb" {
  description = "Enable DynamoDB permissions for the provided tables"
  type        = bool
  default     = false
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs the task role can access"
  type        = list(string)
  default     = []
}

variable "enable_sqs_send_receive" {
  description = "Enable SQS send/receive permissions for the provided queues"
  type        = bool
  default     = false
}

variable "sqs_queue_arns" {
  description = "List of SQS queue ARNs the task role can interact with"
  type        = list(string)
  default     = []
}

variable "enable_sns_publish" {
  description = "Enable SNS publish permissions for the provided topics"
  type        = bool
  default     = false
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs the task role can publish to"
  type        = list(string)
  default     = []
}

variable "enable_ses_templated_email" {
  description = "Enable SES templated email permissions for the provided identities"
  type        = bool
  default     = false
}

variable "ses_identity_arns" {
  description = "List of SES identity ARNs allowed for templated email sending"
  type        = list(string)
  default     = []
}

variable "enable_sts_assume_role" {
  description = "Enable sts:AssumeRole for the provided role ARNs"
  type        = bool
  default     = false
}

variable "assumable_role_arns" {
  description = "List of role ARNs the task role is allowed to assume"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs permissions on the provided log groups for the execution role"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_arns" {
  description = "List of CloudWatch Log Group ARNs the execution role can write to"
  type        = list(string)
  default     = []
}

variable "enable_ecr_pull" {
  description = "Enable ECR pull permissions on the provided repositories for the execution role"
  type        = bool
  default     = true
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs the execution role can pull images from"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
