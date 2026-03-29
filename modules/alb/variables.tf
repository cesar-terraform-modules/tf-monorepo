variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 32
    error_message = "Name must be between 1 and 32 characters"
  }

  validation {
    condition     = !startswith(var.name, "internal-")
    error_message = "Name cannot begin with 'internal-' (AWS restriction)"
  }
}

variable "internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach the ALB to. Must span at least 2 availability zones"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for an ALB"
  }
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the ALB on ports 80 and 443"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_groups" {
  description = "List of target group configurations to create"
  type = list(object({
    name                 = string
    port                 = number
    protocol             = string
    health_check_path    = string
    health_check_matcher = string
  }))

  validation {
    condition     = length(var.target_groups) > 0
    error_message = "At least one target group must be defined"
  }

  validation {
    condition     = alltrue([for tg in var.target_groups : contains(["HTTP", "HTTPS"], tg.protocol)])
    error_message = "Target group protocol must be HTTP or HTTPS"
  }
}

variable "enable_https" {
  description = "Whether to create an HTTPS listener on port 443"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener. Required if enable_https is true"
  type        = string
  default     = null
}

variable "http_default_action" {
  description = "Default action for the HTTP listener. Use 'forward' to forward to the first target group or 'redirect' to redirect to HTTPS"
  type        = string
  default     = "forward"

  validation {
    condition     = contains(["forward", "redirect"], var.http_default_action)
    error_message = "http_default_action must be 'forward' or 'redirect'"
  }
}

variable "listener_rules" {
  description = "Optional path-based routing rules mapping path patterns to target group names"
  type = list(object({
    priority          = number
    path_patterns     = list(string)
    target_group_name = string
  }))
  default = []
}

variable "health_check_interval" {
  description = "Interval in seconds between health checks"
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds"
  }
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks before considering a target healthy"
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_healthy_threshold >= 2 && var.health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10"
  }
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before considering a target unhealthy"
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_unhealthy_threshold >= 2 && var.health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
