locals {
  crossaccount_enabled = length(var.trusted_account_ids) > 0
  needs_bucket_policy  = var.public_read_only || local.crossaccount_enabled

  // Grouped by access level so the document holds a fixed number of statements rather than one per
  // account. Bucket policies are capped at 20KB.
  trusted_all_account_ids   = distinct([for acct in var.trusted_account_ids : acct.account_id])
  trusted_read_account_ids  = distinct([for acct in var.trusted_account_ids : acct.account_id if acct.access_level == "read"])
  trusted_write_account_ids = distinct([for acct in var.trusted_account_ids : acct.account_id if acct.access_level == "write"])

  // Each trusted account is named as a root principal rather than matched with the
  // s3:DataAccessPointAccount condition. That condition key is only defined for the `accesspoint`
  // and `accesspointobject` resource types (see the Service Authorization Reference), never for
  // `bucket` or `object` -- and S3 enforces this for object reads: a bucket policy statement
  // conditioning s3:GetObject on it can never match, because the key is absent from the request
  // context of an object-typed resource. The result is a delegation that lists and reads tags but
  // fails every GetObject with "no resource-based policy allows the s3:GetObject action".
  //
  // Naming the account root still delegates rather than grants: which principals in the trusted
  // account can use this is decided by that account's own IAM and access point policies. What is
  // lost is pinning the trusted account to its access points -- there is no condition key S3
  // supports on bucket-typed resources that could do that. The level granted here remains the
  // ceiling either way, and fixed principals keep the statements non-public, so
  // block_public_policy stays enabled.
  trusted_all_principals   = [for id in local.trusted_all_account_ids : "arn:aws:iam::${id}:root"]
  trusted_read_principals  = [for id in local.trusted_read_account_ids : "arn:aws:iam::${id}:root"]
  trusted_write_principals = [for id in local.trusted_write_account_ids : "arn:aws:iam::${id}:root"]

  // s3:GetBucketLocation and s3:ListBucketMultipartUploads stay out: neither can be addressed
  // through an access point at all, so granting them here would widen direct bucket access without
  // enabling anything for the access-point consumers this feature exists for.
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
      error_message = "public_read_only cannot be combined with trusted_account_ids. A public bucket policy activates RestrictPublicBuckets, which blocks the cross-account delegation."
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

  // Delegates access control to the trusted accounts. This is deliberately grant-agnostic: each
  // consumer creates its own access point in its own account and controls which of its
  // applications may use it, so these statements never change per consumer.

  // Bucket-scoped listing is identical for both access levels, so every trusted account shares one
  // statement. Read-only accounts are still expected to list the bucket.
  dynamic "statement" {
    for_each = length(local.trusted_all_principals) > 0 ? [local.trusted_all_principals] : []

    content {
      sid     = "DelegateListToTrustedAccounts"
      effect  = "Allow"
      actions = local.crossaccount_bucket_actions
      principals {
        identifiers = statement.value
        type        = "AWS"
      }
      resources = [aws_s3_bucket.this.arn]
    }
  }

  dynamic "statement" {
    for_each = length(local.trusted_read_principals) > 0 ? [local.trusted_read_principals] : []

    content {
      sid     = "DelegateReadToTrustedAccounts"
      effect  = "Allow"
      actions = local.crossaccount_read_object_actions
      principals {
        identifiers = statement.value
        type        = "AWS"
      }
      resources = ["${aws_s3_bucket.this.arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(local.trusted_write_principals) > 0 ? [local.trusted_write_principals] : []

    content {
      sid     = "DelegateWriteToTrustedAccounts"
      effect  = "Allow"
      actions = local.crossaccount_write_object_actions
      principals {
        identifiers = statement.value
        type        = "AWS"
      }
      resources = ["${aws_s3_bucket.this.arn}/*"]
    }
  }
}
