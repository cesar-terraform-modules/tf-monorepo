# Unit tests for ses-email module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "test_identity_and_template_defaults" {
  command = plan

  variables {
    from_email = "reports@example.com"
    tags = {
      Service = "retroboard"
    }
  }

  assert {
    condition     = length(aws_sesv2_email_identity.identity) == 1
    error_message = "Email identity should be created when verification is not skipped"
  }

  assert {
    condition     = aws_sesv2_email_identity.identity[0].email_identity == "reports@example.com"
    error_message = "Email identity should match from_email"
  }

  assert {
    condition     = aws_sesv2_email_identity.identity[0].tags["Service"] == "retroboard"
    error_message = "Tags should be applied to the identity resource"
  }

  assert {
    condition     = can(regex("{{board_name}}", aws_ses_template.this.subject))
    error_message = "Subject should preserve board_name placeholder"
  }

  assert {
    condition     = can(regex("{{summary_url}}", aws_ses_template.this.html))
    error_message = "HTML body should include summary_url placeholder"
  }

  assert {
    condition     = can(regex("{{completed_items}}", aws_ses_template.this.text))
    error_message = "Text body should include completed_items placeholder"
  }
}

run "test_skip_identity_uses_existing" {
  command = plan

  variables {
    from_email                 = "verified@example.com"
    skip_identity_verification = true
  }

  assert {
    condition     = length(aws_sesv2_email_identity.identity) == 0
    error_message = "Identity resource should be skipped when skip_identity_verification is true"
  }

  assert {
    condition     = length(data.aws_sesv2_email_identity.existing) == 1
    error_message = "Existing identity data source should be used when skipping verification"
  }

  assert {
    condition     = aws_ses_template.this.name == "retroboard-summary"
    error_message = "Template should still be created when skipping identity verification"
  }
}
