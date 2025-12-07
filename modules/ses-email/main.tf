terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# Use a dedicated provider configuration so the module can be region-agnostic.
provider "aws" {
  region = var.region
}

locals {
  identity_value = var.from_email
}

resource "aws_sesv2_email_identity" "identity" {
  count          = var.skip_identity_verification ? 0 : 1
  email_identity = local.identity_value

  tags = var.tags
}

data "aws_sesv2_email_identity" "existing" {
  count          = var.skip_identity_verification ? 1 : 0
  email_identity = local.identity_value
}

resource "aws_ses_template" "this" {
  name    = var.template_name
  subject = var.subject
  html    = var.html_body
  text    = var.text_body
}
