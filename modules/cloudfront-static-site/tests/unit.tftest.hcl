# Unit tests for cloudfront-static-site module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "default_configuration" {
  command = plan

  variables {
    bucket_name           = "unit-static-site-bucket"
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
    custom_domain_aliases = ["static.example.com"]
    tags = {
      Environment = "unit"
    }
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_root_object == "index.html"
    error_message = "Default root object should be index.html"
  }

  assert {
    condition     = length(aws_s3_bucket.logs) == 1
    error_message = "Logging bucket should be created by default"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.tags["Environment"] == "unit"
    error_message = "Tags should propagate to the CloudFront distribution"
  }
}

run "default_certificate_toggle" {
  command = plan

  variables {
    bucket_name                    = "unit-static-site-default-cert"
    cloudfront_default_certificate = true
    tags                           = {}
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "CloudFront default certificate should be enabled when requested"
  }
}

run "logging_to_existing_bucket" {
  command = plan

  variables {
    bucket_name           = "unit-static-site-with-logging"
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
    logging_enabled       = true
    create_logging_bucket = false
    logging_bucket_name   = "external-log-bucket"
    log_prefix            = "cf/"
    log_include_cookies   = true
  }

  assert {
    condition     = length(aws_s3_bucket.logs) == 0
    error_message = "No logging bucket should be created when create_logging_bucket is false"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.logging_config[0].bucket == "external-log-bucket.s3.amazonaws.com"
    error_message = "Logging should target the provided external bucket"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.logging_config[0].prefix == "cf/"
    error_message = "Logging prefix should match provided value"
  }
}

run "security_headers_policy_contents" {
  command = plan

  variables {
    bucket_name         = "unit-security-headers"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
  }

  assert {
    condition     = aws_cloudfront_response_headers_policy.security.security_headers_config[0].strict_transport_security[0].include_subdomains == true
    error_message = "Strict-Transport-Security should include subdomains"
  }

  assert {
    condition     = aws_cloudfront_response_headers_policy.security.security_headers_config[0].frame_options[0].frame_option == "DENY"
    error_message = "Frame options should deny framing"
  }
}
