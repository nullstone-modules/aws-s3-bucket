locals {
  // Normalized so every policy has a filter of the same shape, whether or not it declared one. An
  // absent filter and an empty filter both mean "every object", which is what S3 does with an empty
  // Filter element.
  lifecycle_filters = {
    for policy in var.lifecycle_policies : policy.id => {
      prefix                   = policy.filter == null ? null : policy.filter.prefix
      object_size_greater_than = policy.filter == null ? null : policy.filter.object_size_greater_than
      object_size_less_than    = policy.filter == null ? null : policy.filter.object_size_less_than
      tags                     = policy.filter == null || try(policy.filter.tags, null) == null ? {} : policy.filter.tags
    }
  }

  // S3 accepts at most one condition directly inside Filter. Two or more have to be wrapped in an
  // `and` block, and `and` in turn is invalid with fewer than two. Counting the conditions each
  // policy actually set is what decides which of the two forms gets emitted below. Every tag counts
  // separately, so two tags alone already require `and`.
  lifecycle_filter_conditions = {
    for id, filter in local.lifecycle_filters : id => (
      (filter.prefix != null ? 1 : 0) +
      (filter.object_size_greater_than != null ? 1 : 0) +
      (filter.object_size_less_than != null ? 1 : 0) +
      length(filter.tags)
    )
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_policies) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  // Pinned rather than left implicit. AWS applies a 128KB floor to transitions by default, and the
  // provider carries that default forward; naming it here means an upgrade can never quietly change
  // which objects a rule moves for buckets whose own configuration never changed.
  transition_default_minimum_object_size = "all_storage_classes_128K"

  dynamic "rule" {
    for_each = var.lifecycle_policies

    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        // Only populated in the single-condition case. With two or more, these stay null and the
        // `and` block below carries all of them instead.
        prefix                   = local.lifecycle_filter_conditions[rule.value.id] == 1 ? local.lifecycle_filters[rule.value.id].prefix : null
        object_size_greater_than = local.lifecycle_filter_conditions[rule.value.id] == 1 ? local.lifecycle_filters[rule.value.id].object_size_greater_than : null
        object_size_less_than    = local.lifecycle_filter_conditions[rule.value.id] == 1 ? local.lifecycle_filters[rule.value.id].object_size_less_than : null

        dynamic "tag" {
          for_each = local.lifecycle_filter_conditions[rule.value.id] == 1 ? local.lifecycle_filters[rule.value.id].tags : {}

          content {
            key   = tag.key
            value = tag.value
          }
        }

        dynamic "and" {
          for_each = local.lifecycle_filter_conditions[rule.value.id] > 1 ? [local.lifecycle_filters[rule.value.id]] : []

          content {
            prefix                   = and.value.prefix
            object_size_greater_than = and.value.object_size_greater_than
            object_size_less_than    = and.value.object_size_less_than
            tags                     = length(and.value.tags) > 0 ? and.value.tags : null
          }
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration == null ? [] : [rule.value.expiration]

        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions

        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration == null ? [] : [rule.value.noncurrent_version_expiration]

        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days == null ? [] : [rule.value.abort_incomplete_multipart_upload_days]

        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}
