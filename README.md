# Terraform Modules Monorepo

[![CI Pipeline](https://github.com/cesar-terraform-modules/tf-monorepo/actions/workflows/ci.yml/badge.svg)](https://github.com/cesar-terraform-modules/tf-monorepo/actions/workflows/ci.yml)

A curated collection of production-ready Terraform modules for AWS infrastructure.

## CI/CD Pipeline

This repository includes a comprehensive CI/CD pipeline that automatically validates:

- **📋 Terraform Formatting**: Ensures all Terraform code follows proper formatting standards
- **✅ Module Tests**: Runs comprehensive test suites for all modules using Terraform's native testing framework
- **🔒 Security Scanning**: Performs security analysis using Trivy to prevent introduction of vulnerabilities

The CI pipeline runs automatically on:
- All pull requests to `main` branch
- All pushes to `main` branch
- Manual workflow dispatch

### Pipeline Status

All checks must pass before code can be merged to ensure:
- Code quality and consistency
- Module functionality and reliability
- Security best practices and compliance

## Available Modules

- **S3 Private Bucket** (`modules/s3-private-bucket`): Private buckets with blocked public access, SSE (AES256/KMS), optional versioning and lifecycle policies. [Docs](./modules/s3-private-bucket/README.md)
- **DynamoDB Global Table** (`modules/dynamodb-global-table`): Tables with multi-region replication, flexible billing modes, PITR, and GSI support. [Docs](./modules/dynamodb-global-table/README.md)
- **Lambda Function** (`modules/lambda-function`): Lambda deploys with IAM roles, logging, VPC support, DLQ, and X-Ray. [Docs](./modules/lambda-function/README.md)
- **Fargate ECS Blue/Green** (`modules/fargate-ecs-bluegreen`): Fargate service with CodeDeploy blue/green, ALB/NLB wiring, EFS and ECS Exec support. [Docs](./modules/fargate-ecs-bluegreen/README.md)
- **Networking Basics** (`modules/networking-basics`): VPC with public/private subnets, optional NAT gateways, flow logs, and hardened default SG. [Docs](./modules/networking-basics/README.md)
- **CloudFront Static Site** (`modules/cloudfront-static-site`): S3 + CloudFront with OAC, minimal security headers, custom domains, logging, and optional WAF. [Docs](./modules/cloudfront-static-site/README.md)
- **ECR Repository** (`modules/ecr-repository`): Secure ECR repo with immutable tags by default, scan-on-push, optional lifecycle and repository policies. [Docs](./modules/ecr-repository/README.md)
- **ECS Task IAM** (`modules/ecs-task-iam`): Task/execution roles with opt-in access to DynamoDB, SQS, SNS, SES, STS assume-role, and ECR/CloudWatch. [Docs](./modules/ecs-task-iam/README.md)
- **SES Email** (`modules/ses-email`): SES identity and reusable summary email template with optional skip verification. [Docs](./modules/ses-email/README.md)
- **SNS Topic** (`modules/sns-topic`): Standard/FIFO topics with optional KMS, flexible subscriptions (HTTP/HTTPS/SQS), topic/delivery policies. [Docs](./modules/sns-topic/README.md)
- **SQS Queue** (`modules/sqs-queue`): Standard or FIFO queue with SSE, optional DLQ, tunable timeouts, and policy attachments. [Docs](./modules/sqs-queue/README.md)
- **RDS Cluster** (`modules/rds-cluster`): Aurora PostgreSQL/MySQL cluster with configurable read replicas, encryption, monitoring, and security best practices. [Docs](./modules/rds-cluster/README.md)

## Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: >= 4.0

## Usage Guidelines

1. **Reference modules** using relative paths from your root module:
   ```hcl
   module "my_bucket" {
     source = "./modules/s3-private-bucket"
     # ... configuration
   }
   ```

2. **Always specify tags** to ensure proper resource organization and cost tracking

3. **Use variables** to parameterize your configurations for different environments

4. **Review module READMEs** for detailed configuration options and examples

## Module Structure

Each module follows a consistent structure:
```
module-name/
├── main.tf         # Main resource definitions
├── variables.tf    # Input variable declarations
├── outputs.tf      # Output value declarations
├── README.md       # Module documentation
└── tests/          # Terraform/OpenTofu test files
    ├── unit.tftest.hcl        # Unit tests
    └── integration.tftest.hcl # Integration tests
```

## Testing

All modules include comprehensive test suites using Terraform's native testing framework. Tests validate module configurations and ensure functionality.

**Quick Start:**
```bash
# Test a specific module
cd modules/s3-private-bucket
terraform test

# Test all modules
for module in modules/*/; do
  terraform -chdir="${module}" test
done
```

For detailed testing instructions, test coverage, and writing new tests, see [TESTING.md](./TESTING.md).

## Contributing

When adding new modules or making changes:
1. Follow the existing module structure
2. Include comprehensive documentation in README.md
3. Use descriptive variable names and include descriptions
4. Tag all resources appropriately
5. Include usage examples
6. **Write comprehensive unit and integration tests**
7. Ensure all tests pass before submitting
8. **Run `terraform fmt -recursive`** to format your code
9. **Review security scan results** - Address any critical or high severity issues

The CI pipeline will automatically verify:
- ✅ Terraform formatting is correct
- ✅ All module tests pass
- ✅ No security vulnerabilities are introduced

All CI checks must pass before your pull request can be merged.

## License

See [LICENSE](./LICENSE) file for details.
