resource "aws_cloudformation_stack_set" "this" {
  name             = var.stack_set_name
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  template_body    = file("${path.module}/stackset-template.yaml")

  parameters = {
    ExternalId         = var.external_id
    RoleName           = var.role_name
    MaxSessionDuration = tostring(var.max_session_duration)
  }

  auto_deployment {
    enabled                          = var.auto_deployment_enabled
    retain_stacks_on_account_removal = var.retain_stacks_on_account_removal
  }

  tags = var.tags
}

resource "aws_cloudformation_stack_set_instance" "this" {
  count = length(var.organizational_unit_ids) > 0 ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.this.name
  regions        = var.deployment_regions

  deployment_targets {
    organizational_unit_ids = var.organizational_unit_ids
  }

  operation_preferences {
    failure_tolerance_percentage = var.operation_failure_tolerance_percentage
    max_concurrent_percentage    = var.operation_max_concurrent_percentage
    region_concurrency_type      = var.operation_region_concurrency_type
    region_order                 = var.operation_region_order
  }
}
