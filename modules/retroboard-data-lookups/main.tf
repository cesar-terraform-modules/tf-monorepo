# Looks up existing infrastructure by project/environment tags and naming conventions.
# Used by downstream appstacks to discover cross-appstack resources without hardcoded IDs.

data "aws_vpc" "this" {
  filter {
    name   = "tag:Project"
    values = [var.project]
  }
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Tier = "public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Tier = "private"
  }
}

data "aws_dynamodb_table" "boards" {
  name = "${var.project}-${var.environment}-boards"
}

data "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
}

data "aws_sqs_queue" "emails" {
  name = "${var.project}-${var.environment}-emails"
}

data "aws_ses_email_identity" "this" {
  email = var.ses_sender_email
}

data "aws_ecr_repository" "repos" {
  for_each = toset(var.ecr_repo_names)
  name     = each.value
}
