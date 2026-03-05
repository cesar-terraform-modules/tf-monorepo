variable "stack_set_name" {
  description = "Name of the CloudFormation StackSet that provisions the StackGen access role."
  type        = string
  default     = "stackgen-org-access-role"
}

variable "external_id" {
  description = "External ID required by the StackGen bastion role when assuming the access role."
  type        = string
  sensitive   = true
}

variable "role_name" {
  description = "Name of the IAM role created in each target account."
  type        = string
  default     = "stackgen-access"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the StackGen access role."
  type        = number
  default     = 3600
}

variable "auto_deployment_enabled" {
  description = "Whether StackSets auto-deploy to new accounts in the target OUs."
  type        = bool
  default     = true
}

variable "retain_stacks_on_account_removal" {
  description = "Whether stacks are retained when accounts are removed from the target OUs."
  type        = bool
  default     = false
}

variable "organizational_unit_ids" {
  description = "List of AWS Organizations OU IDs targeted by the StackSet."
  type        = list(string)
  default     = []
}

variable "deployment_regions" {
  description = "AWS regions where StackSet instances are deployed."
  type        = list(string)
  default     = ["us-east-1"]
}

variable "operation_failure_tolerance_percentage" {
  description = "Percentage of stacks that can fail before the operation is considered failed."
  type        = number
  default     = 0
}

variable "operation_max_concurrent_percentage" {
  description = "Maximum percentage of accounts to deploy to concurrently per region."
  type        = number
  default     = 100
}

variable "operation_region_concurrency_type" {
  description = "Region concurrency type for StackSet operations (PARALLEL or SEQUENTIAL)."
  type        = string
  default     = "PARALLEL"
}

variable "operation_region_order" {
  description = "Ordered list of regions for SEQUENTIAL region concurrency."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the StackSet."
  type        = map(string)
  default     = {}
}
