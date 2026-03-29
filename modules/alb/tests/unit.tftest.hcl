# Unit tests for alb module
# These tests validate the module configuration without creating actual resources

mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      id         = "vpc-12345678"
      cidr_block = "10.0.0.0/16"
    }
  }
}

run "test_basic_alb_configuration" {
  command = plan

  variables {
    name       = "test-alb"
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  # Verify ALB is created with correct name
  assert {
    condition     = aws_lb.this.name == "test-alb"
    error_message = "ALB name should match the input variable"
  }

  # Verify ALB is internet-facing by default
  assert {
    condition     = aws_lb.this.internal == false
    error_message = "ALB should be internet-facing by default"
  }

  # Verify ALB type is application
  assert {
    condition     = aws_lb.this.load_balancer_type == "application"
    error_message = "ALB type should be application"
  }

  # Verify security group is created
  assert {
    condition     = aws_security_group.this.name == "test-alb-alb-sg"
    error_message = "Security group name should follow naming convention"
  }
}

run "test_internal_alb" {
  command = plan

  variables {
    name       = "priv-alb"
    internal   = true
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  assert {
    condition     = aws_lb.this.internal == true
    error_message = "ALB should be internal when internal=true"
  }
}

run "test_security_group_http_ingress" {
  command = plan

  variables {
    name          = "test-alb"
    vpc_id        = "vpc-12345678"
    subnet_ids    = ["subnet-12345678", "subnet-87654321"]
    allowed_cidrs = ["10.0.0.0/16", "192.168.0.0/16"]
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  # Verify HTTP ingress rules are created for each CIDR
  assert {
    condition     = length(aws_security_group_rule.ingress_http) == 2
    error_message = "Should create HTTP ingress rules for each allowed CIDR"
  }

  # Verify HTTPS ingress rules are not created when enable_https is false
  assert {
    condition     = length(aws_security_group_rule.ingress_https) == 0
    error_message = "Should not create HTTPS ingress rules when enable_https is false"
  }

  # Verify egress rule exists
  assert {
    condition     = aws_security_group_rule.egress_vpc.type == "egress"
    error_message = "Should create egress rule to VPC CIDR"
  }
}

run "test_https_security_group_rules" {
  command = plan

  variables {
    name            = "test-alb"
    vpc_id          = "vpc-12345678"
    subnet_ids      = ["subnet-12345678", "subnet-87654321"]
    allowed_cidrs   = ["10.0.0.0/16"]
    enable_https    = true
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  # Verify HTTPS ingress rules are created
  assert {
    condition     = length(aws_security_group_rule.ingress_https) == 1
    error_message = "Should create HTTPS ingress rules when enable_https is true"
  }

  # Verify HTTPS listener is created
  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "Should create HTTPS listener when enable_https is true"
  }

  assert {
    condition     = aws_lb_listener.https[0].port == 443
    error_message = "HTTPS listener should be on port 443"
  }
}

run "test_target_group_configuration" {
  command = plan

  variables {
    name       = "test-alb"
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    target_groups = [
      {
        name                 = "api-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/api/health"
        health_check_matcher = "200"
      },
      {
        name                 = "web-tg"
        port                 = 3000
        protocol             = "HTTP"
        health_check_path    = "/"
        health_check_matcher = "200-299"
      }
    ]
  }

  # Verify both target groups are created
  assert {
    condition     = length(aws_lb_target_group.this) == 2
    error_message = "Should create two target groups"
  }

  # Verify target type is ip (for Fargate)
  assert {
    condition     = aws_lb_target_group.this["api-tg"].target_type == "ip"
    error_message = "Target type should be ip for Fargate compatibility"
  }

  assert {
    condition     = aws_lb_target_group.this["api-tg"].port == 8080
    error_message = "API target group port should be 8080"
  }

  assert {
    condition     = aws_lb_target_group.this["web-tg"].port == 3000
    error_message = "Web target group port should be 3000"
  }
}

run "test_http_forward_listener" {
  command = plan

  variables {
    name                = "test-alb"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    http_default_action = "forward"
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  # Verify forward listener is created
  assert {
    condition     = length(aws_lb_listener.http_forward) == 1
    error_message = "Should create HTTP forward listener"
  }

  assert {
    condition     = aws_lb_listener.http_forward[0].port == 80
    error_message = "HTTP listener should be on port 80"
  }

  # Verify redirect listener is not created
  assert {
    condition     = length(aws_lb_listener.http_redirect) == 0
    error_message = "Should not create redirect listener when action is forward"
  }
}

run "test_http_redirect_listener" {
  command = plan

  variables {
    name                = "test-alb"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    http_default_action = "redirect"
    enable_https        = true
    certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  # Verify redirect listener is created
  assert {
    condition     = length(aws_lb_listener.http_redirect) == 1
    error_message = "Should create HTTP redirect listener"
  }

  # Verify forward listener is not created
  assert {
    condition     = length(aws_lb_listener.http_forward) == 0
    error_message = "Should not create forward listener when action is redirect"
  }
}

run "test_tags_are_applied" {
  command = plan

  variables {
    name       = "test-alb"
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
    tags = {
      Environment = "test"
      Project     = "testing"
    }
  }

  assert {
    condition     = aws_lb.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied to ALB"
  }

  assert {
    condition     = aws_lb.this.tags["Name"] == "test-alb"
    error_message = "Name tag should be automatically added to ALB"
  }

  assert {
    condition     = aws_security_group.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied to security group"
  }

  assert {
    condition     = aws_lb_target_group.this["test-tg"].tags["Environment"] == "test"
    error_message = "Environment tag should be applied to target groups"
  }
}

run "test_health_check_defaults" {
  command = plan

  variables {
    name       = "test-alb"
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-12345678", "subnet-87654321"]
    target_groups = [
      {
        name                 = "test-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  assert {
    condition     = aws_lb_target_group.this["test-tg"].health_check[0].path == "/health"
    error_message = "Health check path should match configuration"
  }

  assert {
    condition     = aws_lb_target_group.this["test-tg"].health_check[0].matcher == "200"
    error_message = "Health check matcher should match configuration"
  }

  assert {
    condition     = aws_lb_target_group.this["test-tg"].health_check[0].interval == 30
    error_message = "Health check interval should default to 30"
  }
}
