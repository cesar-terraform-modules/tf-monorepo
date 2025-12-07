# Integration tests for cloudfront-static-site module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_static_site_with_logging" {
  command = plan

  variables {
    bucket_name                    = "integration-static-site-12345"
    cloudfront_default_certificate = true
    logging_enabled                = true
    force_destroy                  = true
    tags = {
      Environment = "integration"
      ManagedBy   = "Terraform"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "integration-static-site-12345"
    error_message = "Static site bucket should be created"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.enabled == true
    error_message = "CloudFront distribution should be enabled"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].cache_policy_id == "658327ea-f89d-4fab-a63d-7e88639e58f6"
    error_message = "Managed caching policy should be used by default"
  }

  assert {
    condition     = length(aws_s3_bucket.logs) == 1
    error_message = "Logging bucket should be created when logging is enabled"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "Default CloudFront certificate should be used in integration test"
  }
}
