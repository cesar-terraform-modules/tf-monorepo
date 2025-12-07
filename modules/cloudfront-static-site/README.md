# CloudFront Static Site Module

This module provisions a private S3 bucket, CloudFront distribution, and supporting resources to serve a static web UI with secure defaults.

## Features

- Private S3 origin secured by CloudFront Origin Access Control (OAC)
- Managed caching defaults with compression enabled
- Minimal security headers via a response headers policy
- Optional CloudFront access logging with an auto-created log bucket
- Custom domain support with ACM certificate or the default CloudFront certificate

## Usage

```hcl
module "cloudfront_static_site" {
  source = "./modules/cloudfront-static-site"

  bucket_name         = "retroboard-static-site"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234"
  custom_domain_aliases = ["retro.example.com"]

  tags = {
    Environment = "prod"
    Project     = "retroboard"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket that stores the static site content. Must be globally unique. | `string` | n/a | yes |
| force_destroy | Allow deleting the bucket even if it contains objects. | `bool` | `false` | no |
| bucket_versioning_enabled | Enable versioning on the S3 bucket. | `bool` | `true` | no |
| default_root_object | Default root object served by CloudFront. | `string` | `"index.html"` | no |
| acm_certificate_arn | ARN of the ACM certificate to use for HTTPS. Required when `cloudfront_default_certificate` is false. | `string` | `null` | no |
| cloudfront_default_certificate | Use the default CloudFront certificate instead of ACM. Useful for tests or non-custom-domain setups. | `bool` | `false` | no |
| custom_domain_aliases | List of custom domain names (CNAMEs) for the distribution. | `list(string)` | `[]` | no |
| kms_key_arn | ARN of the KMS key used to encrypt the S3 bucket. If null and `create_kms_key` is true, a key is created. | `string` | `null` | no |
| create_kms_key | Create a KMS key for the S3 bucket when `kms_key_arn` is not provided. | `bool` | `true` | no |
| minimum_protocol_version | Minimum TLS protocol version for the viewer certificate. | `string` | `"TLSv1.2_2021"` | no |
| price_class | CloudFront price class to control the edge locations used. | `string` | `"PriceClass_100"` | no |
| wait_for_deployment | Wait for the CloudFront distribution to finish deploying. | `bool` | `true` | no |
| logging_enabled | Enable access logging for the CloudFront distribution. | `bool` | `true` | no |
| create_logging_bucket | Create an S3 bucket for CloudFront access logs when logging is enabled. | `bool` | `true` | no |
| logging_bucket_name | Name of the logging bucket. If null and `create_logging_bucket` is true, a name is derived from `bucket_name`. | `string` | `null` | no |
| logging_force_destroy | Allow deleting the logging bucket even if it contains objects. | `bool` | `false` | no |
| enable_bucket_logging | Enable S3 server access logging for the content bucket (uses the logging bucket). | `bool` | `true` | no |
| log_include_cookies | Include cookies in access logs. | `bool` | `false` | no |
| log_prefix | Prefix for CloudFront access log objects. | `string` | `"cloudfront/"` | no |
| tags | Map of tags to apply to resources. | `map(string)` | `{}` | no |
| create_waf | Create a WAFv2 web ACL to protect the CloudFront distribution. | `bool` | `true` | no |
| waf_web_acl_arn | Optional existing WAFv2 web ACL ARN to attach. Required when `create_waf` is false. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| distribution_id | ID of the CloudFront distribution. |
| distribution_domain_name | Domain name of the CloudFront distribution. |
| bucket_name | Name of the S3 bucket storing the static site. |
| bucket_arn | ARN of the S3 bucket storing the static site. |

## Prerequisites

- ACM certificate in `us-east-1` when providing `acm_certificate_arn` for custom domains
- DNS records pointing to the CloudFront distribution when using custom aliases

## Testing

This module ships with unit and integration tests runnable via Terraform test:

```bash
cd modules/cloudfront-static-site
terraform test
```

See [TESTING.md](../../TESTING.md) for additional guidance.
