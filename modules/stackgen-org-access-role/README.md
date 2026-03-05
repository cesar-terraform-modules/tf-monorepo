# StackGen Org Access Role StackSet Module

This module provisions a CloudFormation StackSet that deploys a StackGen access IAM role and managed policy to AWS Organization accounts using the SERVICE_MANAGED permission model.

## Features

- IAM role trust policy restricted to the StackGen bastion role with an external ID condition
- Separate sts:TagSession statement for session tagging
- Managed policy with common IAM provisioning actions for Terraform automation platforms
- StackSet auto-deployment controls, operation preferences, and OU-based targeting
- CloudFormation template maintained as a separate file (`stackset-template.yaml`)

## Usage

```hcl
module "stackgen_org_access_role" {
  source = "./modules/stackgen-org-access-role"

  external_id = var.stackgen_external_id

  organizational_unit_ids = [
    "ou-abcd-11111111",
    "ou-abcd-22222222",
  ]

  deployment_regions = ["us-east-1", "us-west-2"]

  auto_deployment_enabled              = true
  retain_stacks_on_account_removal     = false
  operation_failure_tolerance_percentage = 0
  operation_max_concurrent_percentage    = 100
  operation_region_concurrency_type      = "PARALLEL"

  tags = {
    Environment = "production"
    Owner       = "platform"
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
| stack_set_name | Name of the CloudFormation StackSet that provisions the StackGen access role. | `string` | `"stackgen-org-access-role"` | no |
| external_id | External ID required by the StackGen bastion role when assuming the access role. | `string` | n/a | yes |
| role_name | Name of the IAM role created in each target account. | `string` | `"stackgen-access"` | no |
| max_session_duration | Maximum session duration in seconds for the StackGen access role. | `number` | `3600` | no |
| auto_deployment_enabled | Whether StackSets auto-deploy to new accounts in the target OUs. | `bool` | `true` | no |
| retain_stacks_on_account_removal | Whether stacks are retained when accounts are removed from the target OUs. | `bool` | `false` | no |
| organizational_unit_ids | List of AWS Organizations OU IDs targeted by the StackSet. | `list(string)` | `[]` | no |
| deployment_regions | AWS regions where StackSet instances are deployed. | `list(string)` | `["us-east-1"]` | no |
| operation_failure_tolerance_percentage | Percentage of stacks that can fail before the operation is considered failed. | `number` | `0` | no |
| operation_max_concurrent_percentage | Maximum percentage of accounts to deploy to concurrently per region. | `number` | `100` | no |
| operation_region_concurrency_type | Region concurrency type for StackSet operations (PARALLEL or SEQUENTIAL). | `string` | `"PARALLEL"` | no |
| operation_region_order | Ordered list of regions for SEQUENTIAL region concurrency. | `list(string)` | `[]` | no |
| tags | Tags applied to the StackSet. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| stack_set_name | Name of the StackSet. |
| stack_set_id | ID of the StackSet. |
| role_name | Name of the IAM role created in each target account. |
| role_arn_format | Role ARN format for target accounts; replace ACCOUNT_ID with the account number. |
| deployment_target_ou_ids | Organizational unit IDs targeted by the StackSet instance. |

## Notes

- When `organizational_unit_ids` is empty, the StackSet is created without any StackSet instances.
- The IAM managed policy is restricted to IAM actions only, focused on provisioning roles, policies, instance profiles, and identity providers.
