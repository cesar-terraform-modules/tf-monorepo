mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

# Unit tests for fargate-ecs-bluegreen module
# These tests validate the module configuration without creating actual resources

run "test_basic_ecs_service" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    service_name = "test-service"
    task_family  = "test-task"
    
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
  }

  # Verify cluster is created by default
  assert {
    condition     = length([for c in [aws_ecs_cluster.this] : c if c != null]) > 0
    error_message = "ECS cluster should be created when create_cluster is true (default)"
  }

  assert {
    condition     = aws_ecs_cluster.this[0].name == "test-cluster"
    error_message = "Cluster name should match"
  }

  # Verify task definition
  assert {
    condition     = aws_ecs_task_definition.this.family == "test-task"
    error_message = "Task family should match"
  }

  assert {
    condition     = aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "Network mode should be awsvpc for Fargate"
  }

  assert {
    condition     = contains(aws_ecs_task_definition.this.requires_compatibilities, "FARGATE")
    error_message = "Task should require FARGATE compatibility"
  }

  # Verify default CPU and memory
  assert {
    condition     = aws_ecs_task_definition.this.cpu == "256"
    error_message = "Default CPU should be 256"
  }

  assert {
    condition     = aws_ecs_task_definition.this.memory == "512"
    error_message = "Default memory should be 512"
  }

  # Verify service
  assert {
    condition     = aws_ecs_service.this.name == "test-service"
    error_message = "Service name should match"
  }

  assert {
    condition     = aws_ecs_service.this.desired_count == 1
    error_message = "Default desired count should be 1"
  }
}

run "test_custom_task_resources" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    service_name = "test-service"
    task_family  = "test-task"
    task_cpu     = "1024"
    task_memory  = "2048"
    
    container_definitions = [
      {
        name      = "app"
        image     = "app:latest"
        essential = true
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify custom CPU and memory
  assert {
    condition     = aws_ecs_task_definition.this.cpu == "1024"
    error_message = "CPU should be 1024"
  }

  assert {
    condition     = aws_ecs_task_definition.this.memory == "2048"
    error_message = "Memory should be 2048"
  }
}

run "test_existing_cluster" {
  command = plan

  variables {
    cluster_name   = "existing-cluster"
    create_cluster = false
    service_name   = "test-service"
    task_family    = "test-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify cluster is not created
  assert {
    condition     = length([for c in [aws_ecs_cluster.this] : c if c != null]) == 0
    error_message = "ECS cluster should not be created when create_cluster is false"
  }
}

run "test_container_insights" {
  command = plan

  variables {
    cluster_name              = "test-cluster"
    enable_container_insights = true
    service_name              = "test-service"
    task_family               = "test-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify container insights is enabled
  assert {
    condition     = aws_ecs_cluster.this[0].setting[0].name == "containerInsights"
    error_message = "Container Insights setting should be configured"
  }

  assert {
    condition     = aws_ecs_cluster.this[0].setting[0].value == "enabled"
    error_message = "Container Insights should be enabled"
  }
}

run "test_execution_role_creation" {
  command = plan

  variables {
    cluster_name           = "test-cluster"
    service_name           = "test-service"
    task_family            = "test-task"
    create_execution_role  = true
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify execution role is created
  assert {
    condition     = length([for r in [aws_iam_role.execution] : r if r != null]) > 0
    error_message = "Execution role should be created when create_execution_role is true"
  }
}

run "test_task_role_creation" {
  command = plan

  variables {
    cluster_name     = "test-cluster"
    service_name     = "test-service"
    task_family      = "test-task"
    create_task_role = true
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify task role is created
  assert {
    condition     = length([for r in [aws_iam_role.task] : r if r != null]) > 0
    error_message = "Task role should be created when create_task_role is true"
  }
}

run "test_external_roles" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    service_name          = "test-service"
    task_family           = "test-task"
    create_execution_role = false
    execution_role_arn    = "arn:aws:iam::123456789012:role/execution-role"
    create_task_role      = false
    task_role_arn         = "arn:aws:iam::123456789012:role/task-role"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify external roles are used
  assert {
    condition     = aws_ecs_task_definition.this.execution_role_arn == "arn:aws:iam::123456789012:role/execution-role"
    error_message = "Should use external execution role"
  }

  assert {
    condition     = aws_ecs_task_definition.this.task_role_arn == "arn:aws:iam::123456789012:role/task-role"
    error_message = "Should use external task role"
  }

  # Verify roles are not created
  assert {
    condition     = length([for r in [aws_iam_role.execution] : r if r != null]) == 0
    error_message = "Execution role should not be created when using external role"
  }

  assert {
    condition     = length([for r in [aws_iam_role.task] : r if r != null]) == 0
    error_message = "Task role should not be created when using external role"
  }
}

run "test_service_scaling" {
  command = plan

  variables {
    cluster_name   = "test-cluster"
    service_name   = "test-service"
    task_family    = "test-task"
    desired_count  = 3
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify desired count
  assert {
    condition     = aws_ecs_service.this.desired_count == 3
    error_message = "Desired count should be 3"
  }
}

run "test_load_balancer_configuration" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    service_name = "test-service"
    task_family  = "test-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
        portMappings = [
          {
            containerPort = 8080
          }
        ]
      }
    ]
    
    load_balancers = [
      {
        target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/abc123"
        container_name   = "app"
        container_port   = 8080
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify load balancer configuration
  assert {
    condition     = length(aws_ecs_service.this.load_balancer) == 1
    error_message = "Should have 1 load balancer configuration"
  }

  assert {
    condition     = aws_ecs_service.this.load_balancer[0].container_name == "app"
    error_message = "Load balancer container name should be 'app'"
  }

  assert {
    condition     = aws_ecs_service.this.load_balancer[0].container_port == 8080
    error_message = "Load balancer container port should be 8080"
  }
}

run "test_service_discovery" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    service_name = "test-service"
    task_family  = "test-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    service_registries = [
      {
        registry_arn   = "arn:aws:servicediscovery:us-east-1:123456789012:service/srv-abc123"
        container_name = "app"
        container_port = 8080
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify service registry configuration
  assert {
    condition     = length(aws_ecs_service.this.service_registries) == 1
    error_message = "Should have 1 service registry"
  }
}

run "test_ecs_exec" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    service_name          = "test-service"
    task_family           = "test-task"
    enable_execute_command = true
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify ECS Exec is enabled
  assert {
    condition     = aws_ecs_service.this.enable_execute_command == true
    error_message = "ECS Exec should be enabled"
  }
}

run "test_blue_green_deployment_enabled" {
  command = plan

  variables {
    cluster_name                 = "test-cluster"
    service_name                 = "test-service"
    task_family                  = "test-task"
    enable_blue_green_deployment = true
    codedeploy_listener_arns     = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-lb/abc123/def456"]
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    load_balancers = [
      {
        target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/abc123"
        container_name   = "app"
        container_port   = 80
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify CodeDeploy resources are created
  assert {
    condition     = length([for app in [aws_codedeploy_app.this] : app if app != null]) > 0
    error_message = "CodeDeploy application should be created when blue-green deployment is enabled"
  }

  assert {
    condition     = length([for dg in [aws_codedeploy_deployment_group.this] : dg if dg != null]) > 0
    error_message = "CodeDeploy deployment group should be created when blue-green deployment is enabled"
  }
}

run "test_blue_green_deployment_disabled" {
  command = plan

  variables {
    cluster_name                 = "test-cluster"
    service_name                 = "test-service"
    task_family                  = "test-task"
    enable_blue_green_deployment = false
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify CodeDeploy resources are not created
  assert {
    condition     = length([for app in [aws_codedeploy_app.this] : app if app != null]) == 0
    error_message = "CodeDeploy application should not be created when blue-green deployment is disabled"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    service_name = "test-service"
    task_family  = "test-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
    
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  # Verify tags are applied
  assert {
    condition     = aws_ecs_cluster.this[0].tags["Environment"] == "test"
    error_message = "Environment tag should be applied to cluster"
  }

  assert {
    condition     = aws_ecs_task_definition.this.tags["Project"] == "testing"
    error_message = "Project tag should be applied to task definition"
  }
}
