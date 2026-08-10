locals {
  crossaccount_enabled = length(var.trusted_access_points) > 0
  needs_bucket_policy  = var.public_read_only || local.crossaccount_enabled

  // Grouped by access level so the document holds a fixed number of statements rather than one per
  // account. Bucket policies are capped at 20KB.
  trusted_all_account_ids   = distinct([for ap in var.trusted_access_points : ap.account_id])
  trusted_read_account_ids  = distinct([for ap in var.trusted_access_points : ap.account_id if ap.access_level == "read"])
  trusted_write_account_ids = distinct([for ap in var.trusted_access_points : ap.account_id if ap.access_level == "write"])

  // Bucket-scoped and object-scoped actions must be split across separate statements. S3 validates
  // the condition against every action/resource combination in a statement, so mixing bucket-level
  // actions with `bucket/*` (or object-level actions with the bucket ARN) produces pairs the
  // s3:DataAccessPointAccount condition cannot apply to, and PutBucketPolicy rejects the whole
  // document with MalformedPolicy.
  //
  // Every action listed here must have an `accesspoint` or `accesspointobject` resource type, since
  // those are the only resource types that carry s3:DataAccessPointAccount. Notably
  // s3:ListBucketMultipartUploads does not, so it cannot be delegated this way.
  crossaccount_bucket_actions = [
    "s3:ListBucket",
    "s3:ListBucketVersions",
  ]

  crossaccount_read_object_actions = [
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:GetObjectVersionTagging",
  ]

  // Write is a superset of read. An account granted write can still be narrowed to less by its own
  // access point policy, but it can never exceed what is granted here.
  crossaccount_write_object_actions = concat(local.crossaccount_read_object_actions, [
    "s3:AbortMultipartUpload",
    "s3:DeleteObject",
    "s3:DeleteObjectTagging",
    "s3:DeleteObjectVersion",
    "s3:DeleteObjectVersionTagging",
    "s3:ListMultipartUploadParts",
    "s3:PutObject",
    "s3:PutObjectTagging",
    "s3:PutObjectVersionTagging",
  ])
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
      error_message = "public_read_only cannot be combined with trusted_access_points. A public bucket policy activates RestrictPublicBuckets, which blocks the cross-account access point delegation."
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
  // which of its applications may use it, so these statements never change per consumer.
  //
  // Conditioning on fixed s3:DataAccessPointAccount values keeps the statements non-public, so
  // block_public_policy can stay enabled.

  // Bucket-scoped listing is identical for both access levels, so every trusted account shares one
  // statement. Read-only accounts are still expected to list the bucket.
  dynamic "statement" {
    for_each = length(local.trusted_all_account_ids) > 0 ? [local.trusted_all_account_ids] : []

    content {
      sid     = "DelegateListToTrustedAccessPoints"
      effect  = "Allow"
      actions = local.crossaccount_bucket_actions
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = [aws_s3_bucket.this.arn]

      condition {
        test     = "StringEquals"
        variable = "s3:DataAccessPointAccount"
        values   = statement.value
      }
    }
  }

  dynamic "statement" {
    for_each = length(local.trusted_read_account_ids) > 0 ? [local.trusted_read_account_ids] : []

    content {
      sid     = "DelegateReadToTrustedAccessPoints"
      effect  = "Allow"
      actions = local.crossaccount_read_object_actions
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = ["${aws_s3_bucket.this.arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "s3:DataAccessPointAccount"
        values   = statement.value
      }
    }
  }

  dynamic "statement" {
    for_each = length(local.trusted_write_account_ids) > 0 ? [local.trusted_write_account_ids] : []

    content {
      sid     = "DelegateWriteToTrustedAccessPoints"
      effect  = "Allow"
      actions = local.crossaccount_write_object_actions
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = ["${aws_s3_bucket.this.arn}/*"]

      condition {
        test     = "StringEquals"
        variable = "s3:DataAccessPointAccount"
        values   = statement.value
      }
    }
  }
}
