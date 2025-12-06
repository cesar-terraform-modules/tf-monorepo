# SES Email Module

Manages SES identity verification and a reusable retroboard summary email template.

## Features

- Identity creation for a sender email address or domain with optional skip when already verified
- SES email template (`retroboard-summary` by default) with subject/body placeholders
- Region-agnostic via configurable provider region
- Tags applied to all supported resources

## Usage

```hcl
module "ses_email" {
  source = "./modules/ses-email"

  from_email  = "reports@example.com"
  region      = "us-east-1"
  tags        = { Environment = "dev" }

  # Optional overrides
  template_name = "retroboard-summary"
  subject       = "Retroboard summary for {{board_name}}"
  html_body     = "<html><body><h2>Retroboard Summary for {{board_name}}</h2></body></html>"
  text_body     = "Retroboard summary for {{board_name}}"
}
```

## Prerequisites

- SES is available and the account/region permits identity creation.
- Sandbox-friendly sender/recipient addresses if running in SES sandbox.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| from_email | Verified SES email address or domain to send retroboard summaries from | `string` | n/a | yes |
| skip_identity_verification | Skip creating/verification of the identity when it is already verified in SES | `bool` | `false` | no |
| template_name | Name for the SES template | `string` | `"retroboard-summary"` | no |
| subject | Subject for the retroboard summary email template | `string` | `"Retroboard summary for {{board_name}}"` | no |
| html_body | HTML body for the retroboard summary email template | `string` | `<html>...` | no |
| text_body | Text body for the retroboard summary email template | `string` | `"Retroboard summary for {{board_name}}. View details at {{summary_url}}. Completed: {{completed_items}}. Pending: {{pending_items}}."` | no |
| region | AWS region to manage SES resources in | `string` | `"us-east-1"` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| identity_arn | ARN of the SES identity (email or domain) |
| template_name | Name of the SES email template |
| template_arn | ARN of the SES email template |

## Testing

This module ships with terraform tests:

- Unit tests: validate identity configuration toggles and template placeholders.
- Integration test: exercises identity creation and template attributes with sandbox-safe inputs.

Run tests:
```bash
cd modules/ses-email
terraform test
```

See [TESTING.md](../../TESTING.md) for more details.
