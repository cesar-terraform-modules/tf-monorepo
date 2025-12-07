terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

locals {
  encryption_type = var.kms_key_id != null ? "KMS" : var.encryption_type

  common_tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutable ? "MUTABLE" : "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.image_scanning_on_push
  }

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = local.encryption_type == "KMS" ? var.kms_key_id : null
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

resource "aws_ecr_repository_policy" "this" {
  count  = var.repository_policy != null ? 1 : 0
  policy = var.repository_policy

  repository = aws_ecr_repository.this.name
}
