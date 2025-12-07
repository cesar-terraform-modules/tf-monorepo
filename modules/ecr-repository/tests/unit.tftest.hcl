# Unit tests for ecr-repository module

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }
}

run "defaults_use_immutable_and_scanning" {
  command = plan

  variables {
    repository_name = "retroboard-default"
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "Image tags should be immutable by default"
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "Image scanning on push should default to true"
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256"
    error_message = "AES256 encryption should be used by default"
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == false
    error_message = "force_delete should default to false"
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 0
    error_message = "Lifecycle policy should not be created when none is provided"
  }

  assert {
    condition     = aws_ecr_repository.this.tags["Name"] == "retroboard-default"
    error_message = "Name tag should be applied to the repository"
  }
}

run "mutable_toggle_allows_overwriting_tags" {
  command = plan

  variables {
    repository_name   = "retroboard-mutable"
    image_tag_mutable = true
    force_delete      = true
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "MUTABLE"
    error_message = "Image tags should be mutable when toggle is enabled"
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == true
    error_message = "force_delete should respect provided value"
  }
}
