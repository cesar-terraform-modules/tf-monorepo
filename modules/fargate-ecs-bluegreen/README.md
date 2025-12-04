# Fargate ECS with Blue/Green Deployment Module

This module creates an AWS ECS Fargate service with optional CodeDeploy blue/green deployment support.

## Features

- **Fargate launch type**: Serverless container orchestration
- **Blue/Green deployments**: Integrated with AWS CodeDeploy for safe deployments
- **IAM role management**: Automatically creates execution and task roles
- **Load balancer integration**: Support for Application and Network Load Balancers
- **Service discovery**: Optional AWS Cloud Map integration
- **Container Insights**: Optional CloudWatch Container Insights
- **ECS Exec**: Optional ECS Exec for debugging
- **EFS volume support**: Mount EFS volumes to containers
- **Flexible deployment configurations**: Multiple CodeDeploy deployment strategies

## Important Notes

When using blue/green deployments (`enable_blue_green_deployment = true`), you must provide:
- `codedeploy_listener_arns` - Production listener ARNs
- `codedeploy_blue_target_group_name` - Blue target group name
- `codedeploy_green_target_group_name` - Green target group name

These resources must be created separately (e.g., ALB/NLB with two target groups).

## Usage

### Basic Fargate service without blue/green

```hcl
module "app_service" {
  source = "./modules/fargate-ecs-bluegreen"

  cluster_name = "my-cluster"
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
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-app"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ]

  desired_count       = 2
  subnet_ids          = ["subnet-12345", "subnet-67890"]
  security_group_ids  = ["sg-12345"]
  assign_public_ip    = false

  enable_blue_green_deployment = false

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Fargate service with blue/green deployment

```hcl
module "app_service_bluegreen" {
  source = "./modules/fargate-ecs-bluegreen"

  cluster_name = "production-cluster"
  service_name = "my-app"
  task_family  = "my-app-task"

  task_cpu    = "1024"
  task_memory = "2048"

  container_definitions = [
    {
      name      = "app"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/my-app"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ]

  desired_count       = 3
  subnet_ids          = ["subnet-12345", "subnet-67890"]
  security_group_ids  = ["sg-12345"]
  assign_public_ip    = false

  load_balancers = [
    {
      target_group_arn = aws_lb_target_group.blue.arn
      container_name   = "app"
      container_port   = 8080
    }
  ]

  health_check_grace_period_seconds = 60

  enable_blue_green_deployment        = true
  codedeploy_deployment_config        = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
  codedeploy_auto_rollback_enabled    = true
  codedeploy_terminate_blue_wait_time = 10

  codedeploy_listener_arns           = [aws_lb_listener.main.arn]
  codedeploy_test_listener_arns      = [aws_lb_listener.test.arn]
  codedeploy_blue_target_group_name  = aws_lb_target_group.blue.name
  codedeploy_green_target_group_name = aws_lb_target_group.green.name

  enable_execute_command = true

  task_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Service with EFS volume

```hcl
module "app_with_efs" {
  source = "./modules/fargate-ecs-bluegreen"

  cluster_name = "my-cluster"
  service_name = "app-with-storage"
  task_family  = "app-with-storage-task"

  task_cpu    = "512"
  task_memory = "1024"

  container_definitions = [
    {
      name      = "app"
      image     = "my-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "efs-storage"
          containerPath = "/mnt/data"
        }
      ]
    }
  ]

  volumes = [
    {
      name = "efs-storage"
      efs_volume_configuration = {
        file_system_id = "fs-12345678"
        root_directory = "/data"
      }
    }
  ]

  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]

  enable_blue_green_deployment = false

  tags = {
    Environment = "production"
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
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| service_name | Name of the ECS service | `string` | n/a | yes |
| task_family | Family name for the task definition | `string` | n/a | yes |
| container_definitions | A list of container definitions in JSON format | `any` | n/a | yes |
| subnet_ids | List of subnet IDs for the service | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs for the service | `list(string)` | n/a | yes |
| create_cluster | Whether to create a new ECS cluster | `bool` | `true` | no |
| enable_container_insights | Enable CloudWatch Container Insights | `bool` | `true` | no |
| task_cpu | The number of CPU units used by the task | `string` | `"256"` | no |
| task_memory | The amount of memory (in MiB) used by the task | `string` | `"512"` | no |
| volumes | A list of volume definitions | `list(any)` | `[]` | no |
| create_execution_role | Whether to create an execution role for the task | `bool` | `true` | no |
| execution_role_arn | ARN of the task execution role | `string` | `null` | no |
| create_task_role | Whether to create a task role | `bool` | `true` | no |
| task_role_arn | ARN of the task role | `string` | `null` | no |
| task_role_additional_policies | List of additional IAM policy ARNs | `list(string)` | `[]` | no |
| desired_count | Number of instances of the task definition | `number` | `1` | no |
| platform_version | Platform version on which to run your service | `string` | `"LATEST"` | no |
| deployment_maximum_percent | Upper limit of running tasks | `number` | `200` | no |
| deployment_minimum_healthy_percent | Lower limit of running tasks | `number` | `100` | no |
| health_check_grace_period_seconds | Grace period for load balancer health checks | `number` | `null` | no |
| assign_public_ip | Assign a public IP address to the ENI | `bool` | `false` | no |
| load_balancers | List of load balancer configurations | `list(object)` | `[]` | no |
| service_registries | Service discovery registries | `list(object)` | `[]` | no |
| enable_execute_command | Enable Amazon ECS Exec | `bool` | `false` | no |
| enable_blue_green_deployment | Enable CodeDeploy blue/green deployment | `bool` | `true` | no |
| create_codedeploy_role | Whether to create an IAM role for CodeDeploy | `bool` | `true` | no |
| codedeploy_role_arn | ARN of the CodeDeploy role | `string` | `null` | no |
| codedeploy_deployment_config | Deployment configuration name | `string` | `"CodeDeployDefault.ECSAllAtOnce"` | no |
| codedeploy_auto_rollback_enabled | Enable automatic rollback | `bool` | `true` | no |
| codedeploy_auto_rollback_events | Events that trigger automatic rollback | `list(string)` | `["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]` | no |
| codedeploy_deployment_ready_action | Action when deployment is ready | `string` | `"CONTINUE_DEPLOYMENT"` | no |
| codedeploy_deployment_ready_wait_time | Wait time before continuing deployment | `number` | `0` | no |
| codedeploy_terminate_blue_action | Action on blue instances | `string` | `"TERMINATE"` | no |
| codedeploy_terminate_blue_wait_time | Wait time before terminating blue instances | `number` | `5` | no |
| codedeploy_listener_arns | ALB/NLB listener ARNs for production traffic | `list(string)` | `[]` | no |
| codedeploy_test_listener_arns | ALB/NLB listener ARNs for test traffic | `list(string)` | `null` | no |
| codedeploy_blue_target_group_name | Name of the blue target group | `string` | `null` | no |
| codedeploy_green_target_group_name | Name of the green target group | `string` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The Amazon Resource Name (ARN) that identifies the cluster |
| cluster_arn | The Amazon Resource Name (ARN) that identifies the cluster |
| cluster_name | The name of the cluster |
| task_definition_arn | Full ARN of the Task Definition |
| task_definition_family | The family of the Task Definition |
| task_definition_revision | The revision of the task in a particular family |
| service_id | The Amazon Resource Name (ARN) that identifies the service |
| service_name | The name of the service |
| execution_role_arn | The ARN of the task execution role |
| task_role_arn | The ARN of the task role |
| codedeploy_app_name | The name of the CodeDeploy application |
| codedeploy_deployment_group_name | The name of the CodeDeploy deployment group |
| codedeploy_role_arn | The ARN of the CodeDeploy IAM role |

## CodeDeploy Deployment Configurations

Available deployment configurations:
- `CodeDeployDefault.ECSLinear10PercentEvery1Minutes` - Shifts 10% every minute
- `CodeDeployDefault.ECSLinear10PercentEvery3Minutes` - Shifts 10% every 3 minutes
- `CodeDeployDefault.ECSCanary10Percent5Minutes` - Shifts 10%, waits 5 min, then remaining 90%
- `CodeDeployDefault.ECSCanary10Percent15Minutes` - Shifts 10%, waits 15 min, then remaining 90%
- `CodeDeployDefault.ECSAllAtOnce` - Shifts all traffic at once

## Testing

This module includes comprehensive test coverage:

- **Unit tests**: Validate ECS cluster creation, task definitions, service configuration, IAM roles, load balancing, service discovery, ECS Exec, blue/green deployment setup, and tag application
- **Integration tests**: Test complete Fargate deployments with multiple containers, EFS volumes, service discovery, and various deployment configurations

Run tests:
```bash
cd modules/fargate-ecs-bluegreen
terraform test
```

See [TESTING.md](../../TESTING.md) for detailed testing instructions.
