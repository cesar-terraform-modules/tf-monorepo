output "identity_arn" {
  description = "ARN of the SES identity (email or domain)"
  value       = try(aws_sesv2_email_identity.identity[0].arn, data.aws_sesv2_email_identity.existing[0].arn)
}

output "template_name" {
  description = "Name of the SES email template"
  value       = aws_ses_template.this.name
}

output "template_arn" {
  description = "ARN of the SES email template"
  value       = aws_ses_template.this.arn
}
