variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput. Valid values are PROVISIONED and PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions. Only required for hash_key and range_key attributes"
  type = list(object({
    name = string
    type = string
  }))
}

variable "read_capacity" {
  description = "The number of read units for this table. Required if billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "The number of write units for this table. Required if billing_mode is PROVISIONED"
  type        = number
  default     = 5
}

variable "global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "point_in_time_recovery_enabled" {
  description = "Whether to enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the CMK that should be used for encryption. If not specified, AWS owned key is used"
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Whether TTL is enabled"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = ""
}

variable "replica_regions" {
  description = "List of regions to create replicas in for global table"
  type        = list(string)
  default     = []
}

variable "replica_kms_key_arns" {
  description = "Map of region to KMS key ARN for replica encryption"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
