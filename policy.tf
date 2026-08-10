locals {
  crossaccount_enabled = length(var.trusted_account_ids) > 0
  needs_bucket_policy  = var.public_read_only || local.crossaccount_enabled
}

// A bucket has exactly one policy, so both the public-read statement and the cross-account
// delegation have to live in the same document.
moved {
  from = aws_s3_bucket_policy.public_read_only
  to   = aws_s3_bucket_policy.this
}

resource "aws_s3_bucket_policy" "this" {
  count = local.needs_bucket_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  lifecycle {
    // A single public statement makes the entire document public, which activates RestrictPublicBuckets.
    // That setting blocks all cross-account access, including non-public delegation to specific accounts, so these two features cannot coexist.
    // It would otherwise fail silently at runtime rather than at apply time.
    precondition {
      condition     = !(var.public_read_only && local.crossaccount_enabled)
      error_message = "public_read_only cannot be combined with trusted_account_ids. A public bucket policy activates RestrictPublicBuckets, which blocks the cross-account access point delegation."
    }
  }
}

data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.public_read_only ? [1] : []

    content {
      sid     = "PublicReadGetObject"
      effect  = "Allow"
      actions = ["s3:GetObject"]
      principals {
        identifiers = ["*"]
        type        = "*"
      }
      resources = ["${aws_s3_bucket.this.arn}/*"]
    }
  }

  // Delegates access control to access points owned by the trusted accounts. This is deliberately
  // grant-agnostic: each consumer creates its own access point in its own account and controls
  // which of its applications may use it, so this statement never changes per consumer.
  //
  // Conditioning on a fixed s3:DataAccessPointAccount keeps the statement non-public, so
  // block_public_policy can stay enabled.
  dynamic "statement" {
    for_each = local.crossaccount_enabled ? [1] : []

    content {
      sid     = "DelegateToCrossAccountAccessPoints"
      effect  = "Allow"
      actions = ["s3:*"]
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "s3:DataAccessPointAccount"
        values   = tolist(var.trusted_account_ids)
      }
    }
  }
}
