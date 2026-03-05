locals {
  template_body = <<-YAML
    AWSTemplateFormatVersion: "2010-09-09"
    Description: StackGen access role for organization accounts via StackSets.
    Parameters:
      RoleName:
        Type: String
      ExternalId:
        Type: String
      MaxSessionDuration:
        Type: Number
    Resources:
      StackGenIamProvisioningPolicy:
        Type: AWS::IAM::ManagedPolicy
        Properties:
          ManagedPolicyName: !Sub "${RoleName}-provisioning"
          Description: IAM provisioning actions for Terraform automation platforms.
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - iam:AddRoleToInstanceProfile
                  - iam:AttachRolePolicy
                  - iam:CreateInstanceProfile
                  - iam:CreateOpenIDConnectProvider
                  - iam:CreatePolicy
                  - iam:CreatePolicyVersion
                  - iam:CreateRole
                  - iam:CreateSAMLProvider
                  - iam:DeleteInstanceProfile
                  - iam:DeleteOpenIDConnectProvider
                  - iam:DeletePolicy
                  - iam:DeletePolicyVersion
                  - iam:DeleteRole
                  - iam:DeleteRolePolicy
                  - iam:DeleteSAMLProvider
                  - iam:DetachRolePolicy
                  - iam:Get*
                  - iam:List*
                  - iam:PassRole
                  - iam:PutRolePolicy
                  - iam:RemoveRoleFromInstanceProfile
                  - iam:SetDefaultPolicyVersion
                  - iam:TagInstanceProfile
                  - iam:TagOpenIDConnectProvider
                  - iam:TagPolicy
                  - iam:TagRole
                  - iam:TagSAMLProvider
                  - iam:UntagInstanceProfile
                  - iam:UntagOpenIDConnectProvider
                  - iam:UntagPolicy
                  - iam:UntagRole
                  - iam:UntagSAMLProvider
                  - iam:UpdateAssumeRolePolicy
                  - iam:UpdateOpenIDConnectProviderThumbprint
                  - iam:UpdateRole
                  - iam:UpdateRoleDescription
                  - iam:UpdateSAMLProvider
                Resource: "*"
      StackGenAccessRole:
        Type: AWS::IAM::Role
        Properties:
          RoleName: !Ref RoleName
          MaxSessionDuration: !Ref MaxSessionDuration
          AssumeRolePolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Principal:
                  AWS: arn:aws:iam::239541129941:role/stackgen-bastion
                Action: sts:AssumeRole
                Condition:
                  StringEquals:
                    sts:ExternalId: !Ref ExternalId
              - Effect: Allow
                Principal:
                  AWS: arn:aws:iam::239541129941:role/stackgen-bastion
                Action: sts:TagSession
          ManagedPolicyArns:
            - !Ref StackGenIamProvisioningPolicy
  YAML
}

resource "aws_cloudformation_stack_set" "this" {
  name             = var.stack_set_name
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  template_body    = local.template_body

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

  stack_set_name = var.stack_set_name
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
