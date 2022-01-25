resource "aws_s3_bucket" "this" {
  bucket        = local.resource_name
  acl           = "private"
  tags          = local.tags
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  // Don't add the policy statement if we don't have any origin access identities
  // The IAM policy would be invalid with no principal identifiers
  dynamic "statement" {
    for_each = length(local.oai_iam_arns) > 0 ? [local.oai_iam_arns] : []

    content {
      sid       = "AllowOriginReadObject"
      actions   = ["s3:GetObject"]
      resources = ["arn:aws:s3:::${local.resource_name}/*"]

      principals {
        type        = "AWS"
        identifiers = statement.value
      }
    }
  }

  statement {
    sid       = "AllowReadBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.resource_name}"]

    principals {
      type        = "AWS"
      identifiers = concat([aws_iam_user.deployer.arn], local.oai_iam_arns)
    }
  }

  statement {
    sid = "AllowDeployerWrite"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::${local.resource_name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.deployer.arn]
    }
  }
}
