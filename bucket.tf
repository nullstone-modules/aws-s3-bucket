resource "aws_s3_bucket" "this" {
  #bridgecrew:skip=CKV_AWS_144: Skipping cross-region replication, not vital for compliance benchmarks
  #bridgecrew:skip=CKV_AWS_18: Skipping cross-region replication, not vital for compliance benchmarks
  #bridgecrew:skip=CKV_AWS_21: This is a false positive, versioning is enabled via aws_s3_bucket_versioning resource
  bucket        = local.resource_name
  tags          = local.tags
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "default" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [
    aws_s3_bucket_ownership_controls.default,
    aws_s3_bucket_public_access_block.this
  ]

  bucket = aws_s3_bucket.this.id
  acl    = var.public_read_only ? "public-read" : "private"
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
    }
  }

  count = var.server_side_encryption ? 1 : 0
}
