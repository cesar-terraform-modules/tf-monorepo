variable "bucket_name" {
  description = "Name of the S3 bucket that stores the static site content. Must be globally unique."
  type        = string
}

variable "force_destroy" {
  description = "Allow deleting the bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "bucket_versioning_enabled" {
  description = "Enable versioning on the S3 bucket."
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Default root object served by CloudFront."
  type        = string
  default     = "index.html"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate to use for HTTPS. Required when cloudfront_default_certificate is false."
  type        = string
  default     = null
}

variable "cloudfront_default_certificate" {
  description = "Use the default CloudFront certificate instead of ACM. Useful for tests or non-custom-domain setups."
  type        = bool
  default     = false
}

variable "custom_domain_aliases" {
  description = "List of custom domain names (CNAMEs) for the distribution."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the S3 bucket. If null and create_kms_key is true, a key is created."
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a KMS key for the S3 bucket when kms_key_arn is not provided."
  type        = bool
  default     = true
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version for the viewer certificate."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "price_class" {
  description = "CloudFront price class to control the edge locations used."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "wait_for_deployment" {
  description = "Wait for the CloudFront distribution to finish deploying."
  type        = bool
  default     = true
}

variable "logging_enabled" {
  description = "Enable access logging for the CloudFront distribution."
  type        = bool
  default     = true
}

variable "create_logging_bucket" {
  description = "Create an S3 bucket for CloudFront access logs when logging is enabled."
  type        = bool
  default     = true
}

variable "logging_bucket_name" {
  description = "Name of the logging bucket. If null and create_logging_bucket is true, a name is derived from bucket_name."
  type        = string
  default     = null
}

variable "logging_force_destroy" {
  description = "Allow deleting the logging bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "enable_bucket_logging" {
  description = "Enable S3 server access logging for the content bucket (uses the logging bucket)."
  type        = bool
  default     = true
}

variable "log_include_cookies" {
  description = "Include cookies in access logs."
  type        = bool
  default     = false
}

variable "log_prefix" {
  description = "Prefix for CloudFront access log objects."
  type        = string
  default     = "cloudfront/"
}

variable "tags" {
  description = "Map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "create_waf" {
  description = "Create a WAFv2 web ACL to protect the CloudFront distribution."
  type        = bool
  default     = true
}

variable "waf_web_acl_arn" {
  description = "Optional existing WAFv2 web ACL ARN to attach. Required when create_waf is false."
  type        = string
  default     = null
}
