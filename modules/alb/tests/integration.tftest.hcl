# Integration tests for alb module
# These tests validate complete ALB configurations

mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      id         = "vpc-12345678"
      cidr_block = "10.0.0.0/16"
    }
  }
}

run "test_complete_http_setup" {
  command = plan

  variables {
    name          = "complete-alb"
    vpc_id        = "vpc-12345678"
    subnet_ids    = ["subnet-12345678", "subnet-87654321"]
    allowed_cidrs = ["10.0.0.0/16"]
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
    listener_rules = [
      {
        priority          = 100
        path_patterns     = ["/api/*"]
        target_group_name = "api-tg"
      }
    ]
    tags = {
      Environment = "staging"
    }
  }

  # Verify ALB
  assert {
    condition     = aws_lb.this.name == "complete-alb"
    error_message = "ALB name should match"
  }

  # Verify target groups
  assert {
    condition     = length(aws_lb_target_group.this) == 2
    error_message = "Should create both target groups"
  }

  # Verify listener rules
  assert {
    condition     = length(aws_lb_listener_rule.this) == 1
    error_message = "Should create one listener rule"
  }

  # Verify HTTP listener (forward)
  assert {
    condition     = length(aws_lb_listener.http_forward) == 1
    error_message = "Should create HTTP forward listener"
  }

  # Verify no HTTPS
  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "Should not create HTTPS listener"
  }
}

run "test_complete_https_with_redirect" {
  command = plan

  variables {
    name                = "https-alb"
    vpc_id              = "vpc-12345678"
    subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    enable_https        = true
    certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
    http_default_action = "redirect"
    target_groups = [
      {
        name                 = "app-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
    tags = {
      Environment = "production"
    }
  }

  # Verify HTTPS listener
  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "Should create HTTPS listener"
  }

  assert {
    condition     = aws_lb_listener.https[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
    error_message = "HTTPS listener should use the provided certificate"
  }

  # Verify HTTP redirect
  assert {
    condition     = length(aws_lb_listener.http_redirect) == 1
    error_message = "Should create HTTP redirect listener"
  }

  assert {
    condition     = length(aws_lb_listener.http_forward) == 0
    error_message = "Should not create HTTP forward listener when redirect is configured"
  }

  # Verify HTTPS ingress rules exist
  assert {
    condition     = length(aws_security_group_rule.ingress_https) == 1
    error_message = "Should create HTTPS ingress rule"
  }
}

run "test_internal_alb_restricted_access" {
  command = plan

  variables {
    name          = "priv-alb"
    internal      = true
    vpc_id        = "vpc-12345678"
    subnet_ids    = ["subnet-12345678", "subnet-87654321"]
    allowed_cidrs = ["10.0.0.0/16"]
    target_groups = [
      {
        name                 = "internal-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/health"
        health_check_matcher = "200"
      }
    ]
  }

  assert {
    condition     = aws_lb.this.internal == true
    error_message = "ALB should be internal"
  }

  assert {
    condition     = length(aws_security_group_rule.ingress_http) == 1
    error_message = "Should create ingress rule for the single allowed CIDR"
  }
}

run "test_custom_health_check_settings" {
  command = plan

  variables {
    name                             = "hc-alb"
    vpc_id                           = "vpc-12345678"
    subnet_ids                       = ["subnet-12345678", "subnet-87654321"]
    health_check_interval            = 10
    health_check_healthy_threshold   = 5
    health_check_unhealthy_threshold = 2
    target_groups = [
      {
        name                 = "hc-tg"
        port                 = 8080
        protocol             = "HTTP"
        health_check_path    = "/ready"
        health_check_matcher = "200-204"
      }
    ]
  }

  assert {
    condition     = aws_lb_target_group.this["hc-tg"].health_check[0].interval == 10
    error_message = "Health check interval should be 10"
  }

  assert {
    condition     = aws_lb_target_group.this["hc-tg"].health_check[0].healthy_threshold == 5
    error_message = "Healthy threshold should be 5"
  }

  assert {
    condition     = aws_lb_target_group.this["hc-tg"].health_check[0].unhealthy_threshold == 2
    error_message = "Unhealthy threshold should be 2"
  }

  assert {
    condition     = aws_lb_target_group.this["hc-tg"].health_check[0].matcher == "200-204"
    error_message = "Health check matcher should be 200-204"
  }
}

run "test_multiple_listener_rules" {
  command = plan

  variables {
    name       = "routing-alb"
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
        health_check_matcher = "200"
      },
      {
        name                 = "admin-tg"
        port                 = 9090
        protocol             = "HTTP"
        health_check_path    = "/admin/health"
        health_check_matcher = "200"
      }
    ]
    listener_rules = [
      {
        priority          = 100
        path_patterns     = ["/api/*"]
        target_group_name = "api-tg"
      },
      {
        priority          = 200
        path_patterns     = ["/app/*", "/static/*"]
        target_group_name = "web-tg"
      },
      {
        priority          = 300
        path_patterns     = ["/admin/*"]
        target_group_name = "admin-tg"
      }
    ]
  }

  assert {
    condition     = length(aws_lb_target_group.this) == 3
    error_message = "Should create three target groups"
  }

  assert {
    condition     = length(aws_lb_listener_rule.this) == 3
    error_message = "Should create three listener rules"
  }
}
