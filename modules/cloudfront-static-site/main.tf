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
  origin_id             = "s3-static-site"
  logging_bucket_name   = var.logging_enabled ? coalesce(var.logging_bucket_name, "${var.bucket_name}-logs") : null
  logging_bucket_domain = var.logging_enabled ? (var.create_logging_bucket ? aws_s3_bucket.logs[0].bucket_domain_name : format("%s.s3.amazonaws.com", var.logging_bucket_name)) : null
  logging_bucket_id     = var.logging_enabled ? (var.create_logging_bucket ? aws_s3_bucket.logs[0].id : var.logging_bucket_name) : null
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  count = var.kms_key_arn == null && var.create_kms_key ? 1 : 0

  description             = "KMS key for encrypting ${var.bucket_name} static site bucket"
  deletion_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_name}-kms"
    }
  )
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = coalesce(var.kms_key_arn, try(aws_kms_key.this[0].arn, null))
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.bucket_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_logging" "this" {
  count  = var.logging_enabled && var.enable_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.create_logging_bucket ? aws_s3_bucket.logs[0].id : var.logging_bucket_name
  target_prefix = "${var.log_prefix}s3-access/"

  depends_on = [aws_s3_bucket.logs]
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_name}-oac"
  description                       = "Origin access control for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.bucket_name}-security-headers"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self';"
      override                = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "Static site for ${var.bucket_name}"
  default_root_object = var.default_root_object
  aliases             = var.custom_domain_aliases
  price_class         = var.price_class
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  wait_for_deployment = var.wait_for_deployment

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
    origin_request_policy_id   = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin
    realtime_log_config_arn    = null
    smooth_streaming           = false
    trusted_signers            = []
    trusted_key_groups         = []
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.cloudfront_default_certificate ? null : var.acm_certificate_arn
    ssl_support_method             = var.cloudfront_default_certificate ? null : "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = var.cloudfront_default_certificate
  }

  dynamic "logging_config" {
    for_each = var.logging_enabled && local.logging_bucket_domain != null ? [true] : []
    content {
      bucket          = local.logging_bucket_domain
      include_cookies = var.log_include_cookies
      prefix          = var.log_prefix
    }
  }

  web_acl_id = var.create_waf ? aws_wafv2_web_acl.this[0].arn : var.waf_web_acl_arn

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.cloudfront_default_certificate || var.acm_certificate_arn != null
      error_message = "Provide acm_certificate_arn or enable cloudfront_default_certificate."
    }

    precondition {
      condition     = !var.logging_enabled || var.create_logging_bucket || var.logging_bucket_name != null
      error_message = "When logging is enabled and not creating a bucket, logging_bucket_name must be set."
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  count = var.create_waf ? 1 : 0

  name  = "${var.bucket_name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.bucket_name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.this.arn}/*"]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.this,
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket" "logs" {
  count         = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket        = local.logging_bucket_name
  force_destroy = var.logging_force_destroy

  tags = merge(
    var.tags,
    {
      Name = local.logging_bucket_name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  count      = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket     = aws_s3_bucket.logs[0].id
  acl        = "log-delivery-write"
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count  = var.logging_enabled && var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudFrontGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs[0].arn
      },
      {
        Sid    = "AWSCloudFrontWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control",
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_acl.logs
  ]
}
