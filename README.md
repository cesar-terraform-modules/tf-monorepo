# Terraform Modules Monorepo

A curated collection of production-ready Terraform modules for AWS infrastructure.

## Available Modules

### 1. S3 Private Bucket (`modules/s3-private-bucket`)
Create secure, private S3 buckets with best practices enabled by default.

**Features:**
- Private by default with all public access blocked
- Server-side encryption (AES256 or KMS)
- Optional versioning
- Lifecycle policies support

**Basic Usage:**
```hcl
module "private_bucket" {
  source = "./modules/s3-private-bucket"

  bucket_name        = "my-private-bucket"
  versioning_enabled = true
  
  tags = {
    Environment = "production"
  }
}
```

[Full documentation →](./modules/s3-private-bucket/README.md)

---

### 2. DynamoDB Global Table (`modules/dynamodb-global-table`)
Create DynamoDB tables with optional multi-region replication for global applications.

**Features:**
- Global table replication across regions
- Flexible billing modes (on-demand or provisioned)
- Server-side encryption with optional KMS
- Point-in-time recovery
- Global Secondary Indexes (GSI) support
- TTL configuration

**Basic Usage:**
```hcl
module "users_table" {
  source = "./modules/dynamodb-global-table"

  table_name   = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  
  attributes = [
    {
      name = "user_id"
      type = "S"
    }
  ]

  replica_regions = ["us-west-2", "eu-west-1"]
  
  tags = {
    Environment = "production"
  }
}
```

[Full documentation →](./modules/dynamodb-global-table/README.md)

---

### 3. Lambda Function (`modules/lambda-function`)
Deploy Lambda functions with automatic IAM role creation and CloudWatch logging.

**Features:**
- Automatic IAM role and policy management
- CloudWatch Logs integration
- VPC support for private resource access
- X-Ray tracing
- Dead letter queue configuration
- Function aliases
- Environment variables

**Basic Usage:**
```hcl
module "api_function" {
  source = "./modules/lambda-function"

  function_name = "api-handler"
  handler       = "index.handler"
  runtime       = "python3.11"
  filename      = "function.zip"
  
  timeout     = 30
  memory_size = 256

  environment_variables = {
    ENVIRONMENT = "production"
  }

  tags = {
    Environment = "production"
  }
}
```

[Full documentation →](./modules/lambda-function/README.md)

---

### 4. Fargate ECS with Blue/Green Deployment (`modules/fargate-ecs-bluegreen`)
Deploy containerized applications on AWS Fargate with CodeDeploy blue/green deployment support.

**Features:**
- Serverless container orchestration with Fargate
- Blue/green deployments via AWS CodeDeploy
- Automatic IAM role creation
- Load balancer integration (ALB/NLB)
- Service discovery support
- Container Insights
- ECS Exec for debugging
- EFS volume support

**Basic Usage:**
```hcl
module "app_service" {
  source = "./modules/fargate-ecs-bluegreen"

  cluster_name = "production-cluster"
  service_name = "my-app"
  task_family  = "my-app-task"

  task_cpu    = "512"
  task_memory = "1024"

  container_definitions = [
    {
      name      = "app"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ]

  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]

  enable_blue_green_deployment = true
  codedeploy_listener_arns     = [aws_lb_listener.main.arn]
  
  tags = {
    Environment = "production"
  }
}
```

[Full documentation →](./modules/fargate-ecs-bluegreen/README.md)

---

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

When adding new modules:
1. Follow the existing module structure
2. Include comprehensive documentation in README.md
3. Use descriptive variable names and include descriptions
4. Tag all resources appropriately
5. Include usage examples
6. **Write comprehensive unit and integration tests**
7. Ensure all tests pass before submitting

## License

See [LICENSE](./LICENSE) file for details.
