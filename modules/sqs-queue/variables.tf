variable "queue_name" {
  description = "Name for the SQS queue. If fifo_queue is true, .fifo is appended when missing."
  type        = string

  validation {
    condition     = length(var.queue_name) > 0
    error_message = "queue_name must not be empty."
  }
}

variable "fifo_queue" {
  description = "Create the queue as FIFO. Defaults to a standard queue."
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds for the queue."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200 seconds."
  }
}

variable "message_retention_seconds" {
  description = "How long messages are retained in seconds."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600 seconds."
  }
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size must be between 1024 and 262144 bytes."
  }
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Customer managed KMS key ARN to use for encryption. When null, SQS-managed SSE is enabled."
  type        = string
  default     = null
}

variable "enable_dlq" {
  description = "Whether to create a dead-letter queue and attach a redrive policy."
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Optional name for the dead-letter queue. Defaults to <queue_name>-dlq."
  type        = string
  default     = null
}

variable "dlq_message_retention_seconds" {
  description = "Retention in seconds for the dead-letter queue."
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "dlq_message_retention_seconds must be between 60 and 1209600 seconds."
  }
}

variable "redrive_max_receive_count" {
  description = "Maximum receives before moving a message to the DLQ."
  type        = number
  default     = 5

  validation {
    condition     = var.redrive_max_receive_count > 0
    error_message = "redrive_max_receive_count must be greater than 0."
  }
}

variable "queue_policy_statements" {
  description = "List of IAM policy statements to attach to the queue."
  type = list(object({
    sid     = optional(string)
    effect  = optional(string)
    actions = list(string)
    principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    resources = optional(list(string))
    conditions = optional(map(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
