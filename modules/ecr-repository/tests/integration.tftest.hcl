# Integration test for ecr-repository module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "integration_repository_with_lifecycle_policy" {
  command = plan

  variables {
    repository_name = "retroboard-integration"
    lifecycle_policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Expire images older than 30 days"
          selection = {
            tagStatus   = "any"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 30
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
    tags = {
      Environment = "test"
      Service     = "retroboard"
    }
  }

  assert {
    condition     = aws_ecr_repository.this.name == "retroboard-integration"
    error_message = "Repository name should match the provided value"
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "Scan on push should be enabled"
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "Repository should default to immutable tags"
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 1
    error_message = "Lifecycle policy resource should be created"
  }

  assert {
    condition     = jsondecode(aws_ecr_lifecycle_policy.this[0].policy).rules[0].selection.countNumber == 30
    error_message = "Lifecycle policy should expire images after 30 days"
  }
}
