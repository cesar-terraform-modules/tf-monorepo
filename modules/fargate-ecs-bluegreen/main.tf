resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0
  name  = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.create_execution_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
  task_role_arn            = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn

  container_definitions = jsonencode(var.container_definitions)

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", null) != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", "ENABLED")
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)

          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", null) != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", "ENABLED")
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name                               = var.service_name
  cluster                            = var.create_cluster ? aws_ecs_cluster.this[0].id : var.cluster_name
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  platform_version                   = var.platform_version
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  deployment_controller {
    type = var.enable_blue_green_deployment ? "CODE_DEPLOY" : "ECS"
  }

  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  enable_execute_command = var.enable_execute_command

  tags = var.tags

  depends_on = [
    aws_iam_role.execution,
    aws_iam_role.task
  ]
}

# CodeDeploy resources for blue/green deployment
resource "aws_codedeploy_app" "this" {
  count            = var.enable_blue_green_deployment ? 1 : 0
  name             = "${var.service_name}-codedeploy"
  compute_platform = "ECS"

  tags = var.tags
}

resource "aws_codedeploy_deployment_group" "this" {
  count                  = var.enable_blue_green_deployment ? 1 : 0
  app_name               = aws_codedeploy_app.this[0].name
  deployment_group_name  = "${var.service_name}-deployment-group"
  service_role_arn       = var.create_codedeploy_role ? aws_iam_role.codedeploy[0].arn : var.codedeploy_role_arn
  deployment_config_name = var.codedeploy_deployment_config

  auto_rollback_configuration {
    enabled = var.codedeploy_auto_rollback_enabled
    events  = var.codedeploy_auto_rollback_events
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = var.codedeploy_deployment_ready_action
      wait_time_in_minutes = var.codedeploy_deployment_ready_action == "STOP_DEPLOYMENT" ? var.codedeploy_deployment_ready_wait_time : null
    }

    terminate_blue_instances_on_deployment_success {
      action                           = var.codedeploy_terminate_blue_action
      termination_wait_time_in_minutes = var.codedeploy_terminate_blue_wait_time
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name
    service_name = aws_ecs_service.this.name
  }

  dynamic "load_balancer_info" {
    for_each = var.codedeploy_blue_target_group_name != null && var.codedeploy_green_target_group_name != null ? [1] : []
    content {
      target_group_pair_info {
        prod_traffic_route {
          listener_arns = var.codedeploy_listener_arns
        }

        dynamic "test_traffic_route" {
          for_each = var.codedeploy_test_listener_arns != null ? [1] : []
          content {
            listener_arns = var.codedeploy_test_listener_arns
          }
        }

        target_group {
          name = var.codedeploy_blue_target_group_name
        }

        target_group {
          name = var.codedeploy_green_target_group_name
        }
      }
    }
  }

  tags = var.tags
}

# IAM roles
locals {
  ecs_task_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  codedeploy_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "execution" {
  count = var.create_execution_role ? 1 : 0

  name               = "${var.task_family}-execution-role"
  assume_role_policy = local.ecs_task_assume_role_policy

  tags = var.tags
}

resource "aws_iam_role" "task" {
  count = var.create_task_role ? 1 : 0

  name               = "${var.task_family}-task-role"
  assume_role_policy = local.ecs_task_assume_role_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_policy" {
  count = var.create_execution_role ? 1 : 0

  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_additional_policies" {
  for_each = var.create_task_role ? toset(var.task_role_additional_policies) : []

  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role" "codedeploy" {
  count = var.enable_blue_green_deployment && var.create_codedeploy_role ? 1 : 0

  name               = "${var.service_name}-codedeploy-role"
  assume_role_policy = local.codedeploy_assume_role_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  count = var.enable_blue_green_deployment && var.create_codedeploy_role ? 1 : 0

  role       = aws_iam_role.codedeploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
