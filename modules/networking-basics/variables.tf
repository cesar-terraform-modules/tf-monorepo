variable "cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/24)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "az_count must be between 1 and 6."
  }
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway per public subnet for private egress"
  type        = bool
  default     = false
}

variable "default_sg_egress_cidr_blocks" {
  description = "IPv4 CIDR blocks allowed for default security group egress; defaults to the VPC CIDR when not set."
  type        = list(string)
  default     = []
}

variable "default_sg_egress_ipv6_cidr_blocks" {
  description = "IPv6 CIDR blocks allowed for default security group egress."
  type        = list(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs (recommended for auditability)."
  type        = bool
  default     = true
}

variable "flow_logs_retention_in_days" {
  description = "Retention period (in days) for the VPC Flow Logs CloudWatch Log Group."
  type        = number
  default     = 90

  validation {
    condition     = var.flow_logs_retention_in_days >= 1
    error_message = "flow_logs_retention_in_days must be at least 1."
  }
}

variable "flow_logs_traffic_type" {
  description = "Traffic type to capture for VPC Flow Logs."
  type        = string
  default     = "REJECT"

  validation {
    condition = contains(
      [
        "ACCEPT",
        "REJECT",
        "ALL"
      ],
      var.flow_logs_traffic_type
    )
    error_message = "flow_logs_traffic_type must be one of ACCEPT, REJECT, or ALL."
  }
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
