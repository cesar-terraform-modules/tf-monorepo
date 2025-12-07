# Integration tests for ses-email module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_creates_identity_and_template" {
  command = apply

  variables {
    from_email    = "sandbox@example.com"
    region        = "us-east-1"
    template_name = "retroboard-summary-integration"
    tags = {
      Environment = "test"
      ManagedBy   = "terraform"
    }
  }

  assert {
    condition     = length(aws_sesv2_email_identity.identity) == 1
    error_message = "Identity should be created for the provided email or domain"
  }

  assert {
    condition     = aws_sesv2_email_identity.identity[0].email_identity == "sandbox@example.com"
    error_message = "Identity should match the provided from_email"
  }

  assert {
    condition     = aws_ses_template.this.name == "retroboard-summary-integration"
    error_message = "Template should be created with the provided name"
  }

  assert {
    condition     = can(regex("{{summary_url}}", aws_ses_template.this.html))
    error_message = "HTML content should include summary_url placeholder"
  }

  assert {
    condition     = can(aws_sesv2_email_identity.identity[0].arn)
    error_message = "Identity ARN should be available after apply"
  }

  assert {
    condition     = can(aws_ses_template.this.arn)
    error_message = "Template ARN should be available after apply"
  }
}
