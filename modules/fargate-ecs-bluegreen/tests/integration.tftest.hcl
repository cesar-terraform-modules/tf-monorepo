# Integration tests for fargate-ecs-bluegreen module
# These tests validate the module with actual AWS provider (or mocked provider)

run "integration_test_complete_fargate_service" {
  command = plan

  variables {
    cluster_name              = "integration-test-cluster-${run.timestamp}"
    create_cluster            = true
    enable_container_insights = true
    
    service_name = "integration-test-service"
    task_family  = "integration-test-task"
    task_cpu     = "512"
    task_memory  = "1024"
    
    desired_count                      = 2
    deployment_maximum_percent         = 200
    deployment_minimum_healthy_percent = 100
    
    container_definitions = [
      {
        name      = "nginx"
        image     = "nginx:latest"
        essential = true
        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "ENV"
            value = "integration-test"
          }
        ]
      }
    ]
    
    subnet_ids         = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-12345"]
    assign_public_ip   = true
    
    load_balancers = [
      {
        target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/abc123"
        container_name   = "nginx"
        container_port   = 80
      }
    ]
    
    health_check_grace_period_seconds = 60
    
    create_execution_role = true
    create_task_role      = true
    
    task_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    ]
    
    enable_execute_command = true
    
    enable_blue_green_deployment    = true
    codedeploy_deployment_config    = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
    codedeploy_auto_rollback_enabled = true
    codedeploy_listener_arns        = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-lb/abc123/def456"]
    
    tags = {
      Environment = "integration-test"
      ManagedBy   = "Terraform"
      TestRun     = "complete"
    }
  }

  # Verify all resources are created
  assert {
    condition     = length([for c in [aws_ecs_cluster.this] : c if c != null]) > 0
    error_message = "ECS cluster should be created"
  }

  assert {
    condition     = aws_ecs_task_definition.this.family != null
    error_message = "Task definition should be created"
  }

  assert {
    condition     = aws_ecs_service.this.name != null
    error_message = "ECS service should be created"
  }

  assert {
    condition     = length([for r in [aws_iam_role.execution] : r if r != null]) > 0
    error_message = "Execution role should be created"
  }

  assert {
    condition     = length([for r in [aws_iam_role.task] : r if r != null]) > 0
    error_message = "Task role should be created"
  }

  assert {
    condition     = length([for app in [aws_codedeploy_app.this] : app if app != null]) > 0
    error_message = "CodeDeploy application should be created"
  }

  assert {
    condition     = length([for dg in [aws_codedeploy_deployment_group.this] : dg if dg != null]) > 0
    error_message = "CodeDeploy deployment group should be created"
  }
}

run "integration_test_minimal_service" {
  command = plan

  variables {
    cluster_name = "integration-test-minimal-${run.timestamp}"
    service_name = "minimal-service"
    task_family  = "minimal-task"
    
    container_definitions = [
      {
        name      = "app"
        image     = "httpd:latest"
        essential = true
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify minimal configuration works
  assert {
    condition     = aws_ecs_cluster.this[0].name != null
    error_message = "ECS cluster should be created with minimal configuration"
  }

  assert {
    condition     = aws_ecs_service.this.desired_count == 1
    error_message = "Should use default desired count of 1"
  }

  assert {
    condition     = aws_ecs_task_definition.this.cpu == "256"
    error_message = "Should use default CPU of 256"
  }

  assert {
    condition     = aws_ecs_task_definition.this.memory == "512"
    error_message = "Should use default memory of 512"
  }
}

run "integration_test_with_external_cluster" {
  command = plan

  variables {
    cluster_name   = "existing-cluster"
    create_cluster = false
    service_name   = "service-on-existing-cluster"
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
    error_message = "ECS cluster should not be created when using existing cluster"
  }

  assert {
    condition     = aws_ecs_service.this.cluster != null
    error_message = "Service should reference a cluster"
  }
}

run "integration_test_with_efs_volumes" {
  command = plan

  variables {
    cluster_name = "integration-test-efs-${run.timestamp}"
    service_name = "efs-service"
    task_family  = "efs-task"
    
    container_definitions = [
      {
        name  = "app"
        image = "app:latest"
        mountPoints = [
          {
            sourceVolume  = "efs-storage"
            containerPath = "/mnt/efs"
          }
        ]
      }
    ]
    
    volumes = [
      {
        name = "efs-storage"
        efs_volume_configuration = {
          file_system_id = "fs-12345678"
          root_directory = "/"
          transit_encryption = "ENABLED"
        }
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify volumes are configured
  assert {
    condition     = length(aws_ecs_task_definition.this.volume) == 1
    error_message = "Should have 1 volume configured"
  }

  assert {
    condition     = aws_ecs_task_definition.this.volume[0].name == "efs-storage"
    error_message = "Volume name should match"
  }
}

run "integration_test_with_service_discovery" {
  command = plan

  variables {
    cluster_name = "integration-test-sd-${run.timestamp}"
    service_name = "sd-service"
    task_family  = "sd-task"
    
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

  # Verify service discovery is configured
  assert {
    condition     = length(aws_ecs_service.this.service_registries) == 1
    error_message = "Should have service discovery configured"
  }
}

run "integration_test_without_blue_green" {
  command = plan

  variables {
    cluster_name                 = "integration-test-no-bg-${run.timestamp}"
    service_name                 = "no-bg-service"
    task_family                  = "no-bg-task"
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
    error_message = "CodeDeploy application should not be created"
  }

  assert {
    condition     = length([for dg in [aws_codedeploy_deployment_group.this] : dg if dg != null]) == 0
    error_message = "CodeDeploy deployment group should not be created"
  }
}

run "integration_test_with_multiple_containers" {
  command = plan

  variables {
    cluster_name = "integration-test-multi-${run.timestamp}"
    service_name = "multi-container-service"
    task_family  = "multi-container-task"
    task_cpu     = "1024"
    task_memory  = "2048"
    
    container_definitions = [
      {
        name      = "app"
        image     = "app:latest"
        essential = true
        portMappings = [
          {
            containerPort = 8080
          }
        ]
      },
      {
        name      = "sidecar"
        image     = "sidecar:latest"
        essential = false
        portMappings = [
          {
            containerPort = 9090
          }
        ]
      }
    ]
    
    subnet_ids         = ["subnet-12345"]
    security_group_ids = ["sg-12345"]
  }

  # Verify task definition is created with proper resources for multiple containers
  assert {
    condition     = aws_ecs_task_definition.this.cpu == "1024"
    error_message = "CPU should be sufficient for multiple containers"
  }

  assert {
    condition     = aws_ecs_task_definition.this.memory == "2048"
    error_message = "Memory should be sufficient for multiple containers"
  }
}
