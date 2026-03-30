variable "project" {
  description = "Project name used in resource naming conventions"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource naming conventions"
  type        = string
}

variable "ses_sender_email" {
  description = "SES verified email address to look up"
  type        = string
}

variable "ecr_repo_names" {
  description = "List of ECR repository names to look up"
  type        = list(string)
  default     = []
}
