variable "from_email" {
  description = "Verified SES email address or domain to send retroboard summaries from"
  type        = string

  validation {
    condition     = length(trimspace(var.from_email)) > 0
    error_message = "from_email must not be empty."
  }
}

variable "skip_identity_verification" {
  description = "Skip creating/verification of the identity when it is already verified in SES"
  type        = bool
  default     = false
}

variable "template_name" {
  description = "Name for the SES template"
  type        = string
  default     = "retroboard-summary"

  validation {
    condition     = length(trimspace(var.template_name)) > 0
    error_message = "template_name must not be empty."
  }
}

variable "subject" {
  description = "Subject for the retroboard summary email template"
  type        = string
  default     = "Retroboard summary for {{board_name}}"
}

variable "html_body" {
  description = "HTML body for the retroboard summary email template"
  type        = string
  default     = <<-HTML
    <html>
      <body>
        <h2>Retroboard Summary for {{board_name}}</h2>
        <p>View the full summary at <a href="{{summary_url}}">{{summary_url}}</a></p>
        <p><strong>Completed items:</strong> {{completed_items}}</p>
        <p><strong>Pending items:</strong> {{pending_items}}</p>
      </body>
    </html>
  HTML
}

variable "text_body" {
  description = "Text body for the retroboard summary email template"
  type        = string
  default     = "Retroboard summary for {{board_name}}. View details at {{summary_url}}. Completed: {{completed_items}}. Pending: {{pending_items}}."
}

variable "region" {
  description = "AWS region to manage SES resources in"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = length(trimspace(var.region)) > 0
    error_message = "region must not be empty."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
