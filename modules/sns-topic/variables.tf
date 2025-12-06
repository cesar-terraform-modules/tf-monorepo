variable "topic_name" {
  description = "The name of the SNS topic"
  type        = string

  validation {
    condition     = trimspace(var.topic_name) != ""
    error_message = "topic_name must not be empty"
  }
}

variable "display_name" {
  description = "The display name for the SNS topic (not supported for FIFO topics)"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Whether to create the topic as FIFO"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topics. Only applied when fifo_topic is true."
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "KMS key ID to use for server-side encryption of the topic"
  type        = string
  default     = null
}

variable "topic_policy" {
  description = "Optional JSON policy for the SNS topic"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "Optional JSON delivery policy for the SNS topic"
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "List of subscription definitions to attach to the topic"
  type = list(object({
    protocol             = string
    endpoint             = string
    raw_message_delivery = optional(bool, false)
    filter_policy        = optional(any, {})
    delivery_policy      = optional(string, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for s in var.subscriptions :
      contains(["http", "https", "sqs"], lower(s.protocol))
    ])
    error_message = "subscriptions.protocol must be one of http, https, or sqs"
  }

  validation {
    condition     = alltrue([for s in var.subscriptions : trimspace(s.endpoint) != ""])
    error_message = "subscriptions.endpoint must not be empty"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
