resource "aws_s3_bucket" "this" {
  #bridgecrew:skip=CKV_AWS_144: Skipping cross-region replication, not vital for compliance benchmarks
  #bridgecrew:skip=CKV_AWS_18: Skipping cross-region replication, not vital for compliance benchmarks
  #bridgecrew:skip=CKV_AWS_21: This is a false positive, versioning is enabled via aws_s3_bucket_versioning resource
  bucket        = local.resource_name
  tags          = local.tags
  force_destroy = true
}

// An object written by another account is owned by that account, and the bucket owner cannot grant
// itself access to an object it does not own -- its own bucket policy does not apply, so a reader
// in the bucket's account gets `AccessDenied ... no resource-based policy allows the s3:GetObject
// action` on an object sitting in its own bucket. BucketOwnerPreferred does not prevent this: it
// only transfers ownership when the writer opts in with a `bucket-owner-full-control` ACL, which
// most SDK clients never send. BucketOwnerEnforced disables ACLs and makes the bucket owner the
// owner of every object unconditionally.
//
// Kept as BucketOwnerPreferred for public buckets, which still set an ACL below. That combination
// cannot receive cross-account writes anyway, since public_read_only and trusted_account_ids are
// mutually exclusive.
resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.public_read_only ? "BucketOwnerPreferred" : "BucketOwnerEnforced"
  }
}

// BucketOwnerEnforced rejects every ACL operation, including a redundant `private`, so the ACL is
// only set where it does something. A private bucket is what S3 gives you with no ACL at all.
resource "aws_s3_bucket_acl" "this" {
  count = var.public_read_only ? 1 : 0

  depends_on = [
    aws_s3_bucket_ownership_controls.default,
    time_sleep.wait-for-public-access-block
  ]

  bucket = aws_s3_bucket.this.id
  acl    = "public-read"
}

resource "time_sleep" "wait-for-public-access-block" {
  triggers = {
    public_read_only = var.public_read_only
  }
  create_duration = "5s"

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = !var.public_read_only
  block_public_policy     = !var.public_read_only
  ignore_public_acls      = !var.public_read_only
  restrict_public_buckets = !var.public_read_only
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"

      // Null rather than an empty string so that a bucket with no key connected produces exactly
      // the configuration it had before this argument existed, and no diff.
      kms_master_key_id = local.kms_key_arn != "" ? local.kms_key_arn : null
    }

    // S3 Bucket Keys collapse the per-object KMS calls into one per bucket per short interval,
    // which is the difference between a KMS bill that tracks object count and one that doesn't.
    // Only set alongside a customer-managed key, to leave existing buckets untouched.
    bucket_key_enabled = local.kms_key_arn != "" ? true : null
  }

  count = local.encryption_enabled ? 1 : 0
}
