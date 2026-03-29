# Data source to get VPC CIDR block for egress rules
data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  target_group_map = { for tg in var.target_groups : tg.name => tg }
}

# Security Group for the ALB
resource "aws_security_group" "this" {
  name        = "${var.name}-alb-sg"
  description = "Security group for ALB ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-alb-sg"
    }
  )
}

# Ingress - HTTP
resource "aws_security_group_rule" "ingress_http" {
  for_each = toset(var.allowed_cidrs)

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this.id
  description       = "Allow HTTP from ${each.value}"
}

# Ingress - HTTPS
resource "aws_security_group_rule" "ingress_https" {
  for_each = var.enable_https ? toset(var.allowed_cidrs) : []

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this.id
  description       = "Allow HTTPS from ${each.value}"
}

# Egress - VPC CIDR
resource "aws_security_group_rule" "egress_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound traffic to VPC CIDR"
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    precondition {
      condition     = !var.enable_https || var.certificate_arn != null
      error_message = "certificate_arn is required when enable_https is true"
    }
  }
}

# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = local.target_group_map

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = each.value.health_check_path
    matcher             = each.value.health_check_matcher
    interval            = var.health_check_interval
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}

# HTTP Listener - forward action
resource "aws_lb_listener" "http_forward" {
  count = var.http_default_action == "forward" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.target_groups[0].name].arn
  }

  tags = var.tags
}

# HTTP Listener - redirect to HTTPS
resource "aws_lb_listener" "http_redirect" {
  count = var.http_default_action == "redirect" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.target_groups[0].name].arn
  }

  tags = var.tags
}

# Path-based Listener Rules (attached to HTTP forward listener or HTTPS listener)
resource "aws_lb_listener_rule" "this" {
  for_each = { for rule in var.listener_rules : rule.priority => rule }

  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http_forward[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_name].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }

  tags = var.tags
}
