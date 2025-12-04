resource "aws_dynamodb_table" "this" {
  name             = var.table_name
  billing_mode     = var.billing_mode
  hash_key         = var.hash_key
  range_key        = var.range_key
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
      read_capacity      = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  server_side_encryption {
    enabled     = var.encryption_enabled
    kms_key_arn = var.kms_key_arn
  }

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
      kms_key_arn = var.replica_kms_key_arns != null ? lookup(var.replica_kms_key_arns, replica.value, null) : null
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )
}
