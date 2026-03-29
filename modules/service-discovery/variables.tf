variable "namespace_name" {
  description = "Name of the private DNS namespace (e.g. retroboard.local)"
  type        = string

  validation {
    condition     = trimspace(var.namespace_name) != ""
    error_message = "namespace_name must not be empty"
  }
}

variable "vpc_id" {
  description = "VPC ID to associate with the private DNS namespace"
  type        = string

  validation {
    condition     = trimspace(var.vpc_id) != ""
    error_message = "vpc_id must not be empty"
  }
}

variable "services" {
  description = "List of services to register in the namespace"
  type = list(object({
    name    = string
    dns_ttl = optional(number, 10)
  }))
  default = []

  validation {
    condition     = alltrue([for s in var.services : trimspace(s.name) != ""])
    error_message = "Each service must have a non-empty name"
  }

  validation {
    condition     = alltrue([for s in var.services : s.dns_ttl > 0])
    error_message = "dns_ttl must be greater than 0"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
