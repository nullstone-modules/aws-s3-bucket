locals {
  lifecycle_transition_enabled = var.transition_to_ia_days > 0 || var.transition_to_glacier_days > 0
  lifecycle_expiration_enabled = var.expiration_days > 0
  lifecycle_noncurrent_enabled = var.noncurrent_version_expiration_days > 0 || var.noncurrent_versions_to_keep > 0
  lifecycle_abort_mpu_enabled  = var.abort_incomplete_multipart_upload_days > 0

  // Every rule is opt-in, so a bucket that sets none of these produces no lifecycle configuration at
  // all rather than an empty one. A bucket created before this feature existed sees no diff.
  //
  // Note that noncurrent_versions_to_keep on its own contributes no rule -- it only modifies the
  // noncurrent expiration rule. It still counts here so the misconfiguration reaches the
  // precondition below and fails at plan time instead of being silently dropped.
  any_lifecycle_rule = (
    local.lifecycle_transition_enabled ||
    local.lifecycle_expiration_enabled ||
    local.lifecycle_noncurrent_enabled ||
    local.lifecycle_abort_mpu_enabled ||
    var.expire_delete_markers
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.any_lifecycle_rule ? 1 : 0

  bucket = aws_s3_bucket.this.id

  // Pinned rather than left implicit. AWS applies a 128KB floor to transitions by default, and the
  // provider carries that default forward; naming it here means an upgrade can never quietly change
  // which objects a rule moves for buckets whose own configuration never changed.
  transition_default_minimum_object_size = "all_storage_classes_128K"

  // Storage class transitions come first so that objects age down through the tiers before any
  // expiration rule removes them.
  dynamic "rule" {
    for_each = local.lifecycle_transition_enabled ? [1] : []

    content {
      id     = "transition-storage-class"
      status = "Enabled"

      // An empty filter applies the rule to every object. The provider requires a filter or a
      // prefix on each rule, so this cannot be omitted.
      filter {}

      dynamic "transition" {
        for_each = var.transition_to_ia_days > 0 ? [1] : []

        content {
          days          = var.transition_to_ia_days
          storage_class = "STANDARD_IA"
        }
      }

      // Glacier Instant Retrieval rather than Glacier Flexible Retrieval: objects stay readable with
      // millisecond latency and no restore step, so a transition can never break an application
      // that still reads the bucket. The tradeoff is a 90-day minimum billing duration.
      dynamic "transition" {
        for_each = var.transition_to_glacier_days > 0 ? [1] : []

        content {
          days          = var.transition_to_glacier_days
          storage_class = "GLACIER_IR"
        }
      }
    }
  }

  dynamic "rule" {
    for_each = local.lifecycle_expiration_enabled ? [1] : []

    content {
      id     = "expire-current-versions"
      status = "Enabled"

      filter {}

      expiration {
        days = var.expiration_days
      }
    }
  }

  dynamic "rule" {
    for_each = local.lifecycle_noncurrent_enabled ? [1] : []

    content {
      id     = "expire-noncurrent-versions"
      status = "Enabled"

      filter {}

      noncurrent_version_expiration {
        noncurrent_days = var.noncurrent_version_expiration_days

        // Null rather than 0 so the rule is written exactly as it was before this argument was
        // offered when the bucket does not use it.
        newer_noncurrent_versions = var.noncurrent_versions_to_keep > 0 ? var.noncurrent_versions_to_keep : null
      }
    }
  }

  // Has to be its own rule. S3 rejects an Expiration element carrying both Days and
  // ExpiredObjectDeleteMarker, so this cannot be folded into expire-current-versions.
  dynamic "rule" {
    for_each = var.expire_delete_markers ? [1] : []

    content {
      id     = "expire-delete-markers"
      status = "Enabled"

      filter {}

      expiration {
        expired_object_delete_marker = true
      }
    }
  }

  dynamic "rule" {
    for_each = local.lifecycle_abort_mpu_enabled ? [1] : []

    content {
      id     = "abort-incomplete-multipart-uploads"
      status = "Enabled"

      filter {}

      abort_incomplete_multipart_upload {
        days_after_initiation = var.abort_incomplete_multipart_upload_days
      }
    }
  }

  lifecycle {
    // These constraints span multiple variables, so they cannot live in a variable validation block
    // without requiring a newer language version than this module targets. S3 rejects each of them
    // at apply time; catching them here reports the problem during plan instead.
    precondition {
      condition     = var.noncurrent_versions_to_keep == 0 || var.noncurrent_version_expiration_days > 0
      error_message = "noncurrent_versions_to_keep only modifies the noncurrent version expiration rule, so it requires noncurrent_version_expiration_days to be set."
    }

    precondition {
      condition     = !(local.lifecycle_expiration_enabled && var.transition_to_ia_days > 0) || var.expiration_days > var.transition_to_ia_days
      error_message = "expiration_days must be greater than transition_to_ia_days. S3 rejects a rule that expires an object before or on the day it transitions."
    }

    precondition {
      condition     = !(local.lifecycle_expiration_enabled && var.transition_to_glacier_days > 0) || var.expiration_days > var.transition_to_glacier_days
      error_message = "expiration_days must be greater than transition_to_glacier_days. S3 rejects a rule that expires an object before or on the day it transitions."
    }

    precondition {
      condition     = !(var.transition_to_ia_days > 0 && var.transition_to_glacier_days > 0) || var.transition_to_glacier_days > var.transition_to_ia_days
      error_message = "transition_to_glacier_days must be greater than transition_to_ia_days. S3 rejects two transitions in the same rule that do not move an object forward through the storage classes."
    }
  }
}
