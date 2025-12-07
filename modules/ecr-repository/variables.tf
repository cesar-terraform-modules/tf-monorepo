variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutable" {
  description = "Whether image tags can be overwritten. Defaults to immutable for safety"
  type        = bool
  default     = false
}

variable "image_scanning_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository. Use AES256 or KMS"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS"
  }
}

variable "kms_key_id" {
  description = "KMS key ARN to use when encryption_type is KMS"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "JSON lifecycle policy document for the repository"
  type        = string
  default     = null

  validation {
    condition     = var.lifecycle_policy == null || can(jsondecode(var.lifecycle_policy))
    error_message = "lifecycle_policy must be valid JSON when provided"
  }
}

variable "repository_policy" {
  description = "JSON repository policy document"
  type        = string
  default     = null

  validation {
    condition     = var.repository_policy == null || can(jsondecode(var.repository_policy))
    error_message = "repository_policy must be valid JSON when provided"
  }
}

variable "force_delete" {
  description = "Delete repository even if images exist"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to apply to the repository"
  type        = map(string)
  default     = {}
}
