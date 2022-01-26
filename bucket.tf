resource "aws_s3_bucket" "this" {
  bucket        = local.resource_name
  acl           = "private"
  tags          = local.tags
  force_destroy = true

  dynamic "server_side_encryption_configuration" {
    for_each = var.server_side_encryption ? ["fake"] : []

    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "aws:kms"
        }
      }
    }
  }
}
