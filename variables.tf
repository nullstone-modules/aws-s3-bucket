variable "versioning" {
  type        = bool
  default     = true
  description = <<EOF
Use the versioning feature of S3 to keep multiple versions of each object stored in your bucket.
With versioning you can list, retrieve, and restore multiple versions of your objects.
EOF
}

variable "server_side_encryption" {
  type        = bool
  default     = true
  description = <<EOF
Encrypts all data at the object level as it is being written to S3, automatically decrypts it as you access it.
The way you access objects (presigned URLs, listing objects, and retrieving objects) all works the same way as if they were not encrypted.
Public urls that are not presigned will not load because the file can't be decrypted.
EOF
}

variable "public_read_only" {
  type        = bool
  default     = false
  description = <<EOF
If toggled on, the contents of this S3 bucket will be made publicly accessible. Public access will be read-only.
The ability to add, remove, or update via authenticated access will remain unchanged.
If you make this bucket public, be sure to turn off server_side_encryption unless you are generating presigned URLs.
When accessing a file via a public url, the file will not be able to be decrypted.
EOF
}

variable "cors_origins" {
  type        = set(string)
  default     = []
  description = <<EOF
A set of origins that are allowed to make requests to this S3 bucket.
Provide a set of origins (e.g. ["https://acme.com", "https://test.com"]) to allow these websites to fetch objects from this bucket.
This is optional. If you don't provide any origins, no CORS configuration will be applied to this bucket.
If you provide origins, you must also provide cors_methods.
EOF
}

variable "cors_methods" {
  type        = set(string)
  default     = ["GET"]
  description = <<EOF
A set of HTTP verbs that are allowed to be used when making CORS requests to this S3 bucket.
This is optional and only used if you also specify cors_origins.
EOF
}

variable "lifecycle_policies" {
  type = list(object({
    id     = string
    status = optional(string, "Enabled")

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string))
    }))

    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))

    transitions = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })), [])

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
    }))

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
      storage_class             = string
    })), [])

    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default     = []
  description = <<EOF
A list of lifecycle policies (rules) to apply to the bucket for automatically expiring, archiving, or transitioning objects.
When nil or empty (the default), no lifecycle configuration is created.
Each policy is made up of a `filter` (which objects it applies to) and one or more actions (what to do and when).

id (required) is a name for the rule, unique within the bucket and up to 255 characters. It appears in the AWS console.
status is `Enabled` or `Disabled`, defaulting to `Enabled`. Disabling a rule keeps it defined but stops it running.

filter selects which objects the rule applies to. Omit it entirely to apply the rule to every object.
  - prefix                    (string) Applies only to objects whose name starts with this prefix.
  - tags                      (map(string)) Applies only to objects carrying all of these tags.
  - object_size_greater_than  (number) Applies only to objects larger than this many bytes.
  - object_size_less_than     (number) Applies only to objects smaller than this many bytes.

expiration deletes objects. Set exactly one of the following:
  - days                          (number) Days since the object's creation.
  - date                          (string) A fixed date, formatted YYYY-MM-DD.
  - expired_object_delete_marker  (bool) Removes delete markers with no versions left underneath them.
                                  This cannot be combined with days or date; use a second policy for that.
On a versioned bucket, expiration deletes the current version and leaves a delete marker rather than removing the
object outright. Reclaiming the storage underneath needs noncurrent_version_expiration as well.

transitions is a list of storage class moves for current versions. Each entry sets storage_class plus exactly one of:
  - days  (number) Days since the object's creation.
  - date  (string) A fixed date, formatted YYYY-MM-DD.

noncurrent_version_expiration deletes old versions, on buckets that have used versioning:
  - noncurrent_days            (number) Days since the version stopped being current.
  - newer_noncurrent_versions  (number) Always retain at least this many of the most recent noncurrent versions,
                               even once they are older than noncurrent_days. Maximum 100.

noncurrent_version_transitions is the same list of storage class moves, applied to noncurrent versions instead.
Each entry sets storage_class, noncurrent_days, and optionally newer_noncurrent_versions.

abort_incomplete_multipart_upload_days (number) aborts uploads that have not completed this many days after starting,
and deletes the parts already uploaded. Those parts are billed as storage but are invisible when listing the bucket.

storage_class, wherever it appears, is one of:
  - STANDARD_IA          Infrequent access, immediately readable. Requires at least 30 days.
  - ONEZONE_IA           As above, stored in a single availability zone. Requires at least 30 days.
  - INTELLIGENT_TIERING  Moves objects between tiers automatically based on access patterns.
  - GLACIER_IR           Archive, still readable in milliseconds with no restore step. 90 day minimum billing.
  - GLACIER              Archive, requires an explicit restore taking minutes to hours. 90 day minimum billing.
  - DEEP_ARCHIVE         Cheapest archive, restores take hours. 180 day minimum billing.
Prefer GLACIER_IR over GLACIER unless nothing reads the bucket directly: GLACIER makes objects unreadable until
restored, which surfaces as errors in any application still fetching them.
EOF

  validation {
    condition     = length(distinct([for policy in var.lifecycle_policies : policy.id])) == length(var.lifecycle_policies)
    error_message = "Each lifecycle_policies[*].id must be unique within the bucket."
  }

  validation {
    condition     = alltrue([for policy in var.lifecycle_policies : length(policy.id) > 0 && length(policy.id) <= 255])
    error_message = "Each lifecycle_policies[*].id must be between 1 and 255 characters."
  }

  validation {
    condition     = alltrue([for policy in var.lifecycle_policies : contains(["Enabled", "Disabled"], policy.status)])
    error_message = "Each lifecycle_policies[*].status must be either Enabled or Disabled."
  }

  // A rule that selects objects but does nothing to them is rejected as MalformedXML.
  validation {
    condition = alltrue([
      for policy in var.lifecycle_policies :
      policy.expiration != null ||
      length(policy.transitions) > 0 ||
      policy.noncurrent_version_expiration != null ||
      length(policy.noncurrent_version_transitions) > 0 ||
      policy.abort_incomplete_multipart_upload_days != null
    ])
    error_message = "Each lifecycle policy must specify at least one action: expiration, transitions, noncurrent_version_expiration, noncurrent_version_transitions, or abort_incomplete_multipart_upload_days."
  }

  validation {
    condition = alltrue(flatten([
      for policy in var.lifecycle_policies : [
        for transition in concat(
          [for t in policy.transitions : t.storage_class],
          [for t in policy.noncurrent_version_transitions : t.storage_class]
        ) : contains(["STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "GLACIER", "DEEP_ARCHIVE"], transition)
      ]
    ]))
    error_message = "Each storage_class must be one of: STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER_IR, GLACIER, DEEP_ARCHIVE."
  }

  validation {
    condition = alltrue(flatten([
      for policy in var.lifecycle_policies : [
        for transition in policy.transitions : (transition.days == null) != (transition.date == null)
      ]
    ]))
    error_message = "Each transition must set exactly one of days or date."
  }

  // S3 requires an object to spend 30 days in Standard before it can move to either IA class.
  validation {
    condition = alltrue(flatten([
      for policy in var.lifecycle_policies : [
        for transition in policy.transitions :
        transition.days == null || transition.days >= 30 || !contains(["STANDARD_IA", "ONEZONE_IA"], transition.storage_class)
      ]
    ]))
    error_message = "A transition to STANDARD_IA or ONEZONE_IA must be at least 30 days."
  }

  // S3 rejects an Expiration element carrying both Days and ExpiredObjectDeleteMarker, so a rule that
  // does both has to be split into two policies.
  validation {
    condition = alltrue([
      for policy in var.lifecycle_policies :
      policy.expiration == null ? true : (
        coalesce(policy.expiration.expired_object_delete_marker, false)
        ? policy.expiration.days == null && policy.expiration.date == null
        : (policy.expiration.days == null) != (policy.expiration.date == null)
      )
    ])
    error_message = "Each expiration must set exactly one of days, date, or expired_object_delete_marker. expired_object_delete_marker cannot be combined with days or date; use a separate policy."
  }

  validation {
    condition = alltrue([
      for policy in var.lifecycle_policies :
      policy.noncurrent_version_expiration == null ? true : (
        policy.noncurrent_version_expiration.noncurrent_days != null ||
        policy.noncurrent_version_expiration.newer_noncurrent_versions != null
      )
    ])
    error_message = "Each noncurrent_version_expiration must set noncurrent_days, newer_noncurrent_versions, or both."
  }

  validation {
    condition = alltrue(flatten([
      for policy in var.lifecycle_policies : concat(
        [
          for t in policy.noncurrent_version_transitions :
          t.newer_noncurrent_versions == null || t.newer_noncurrent_versions <= 100
        ],
        policy.noncurrent_version_expiration == null ? [] : [
          policy.noncurrent_version_expiration.newer_noncurrent_versions == null ||
          policy.noncurrent_version_expiration.newer_noncurrent_versions <= 100
        ]
      )
    ]))
    error_message = "newer_noncurrent_versions cannot exceed 100. S3 does not accept a larger value."
  }
}

variable "trusted_account_ids" {
  type = list(object({
    account_id   = string
    access_level = string
  }))
  default     = []
  description = <<EOF
A list of AWS accounts allowed to read or write this bucket, typically through an S3 access point they own, and how much access each one gets.
`account_id` is a 12-digit AWS account ID. `access_level` is either "read" or "write", where "write" also includes read.
Each listed account decides which of its own principals may use the grant (usually via an access point it creates), so you grant trust once per account, not once per application.
The level you grant here is a ceiling: the consuming account can narrow it further with its own access point and IAM policies, but it can never widen it.
The grant is to the account itself, not pinned to its access points: S3 does not honor the access point condition keys on bucket-typed resources, so a via-access-point-only restriction is not enforceable in a bucket policy.
This cannot be combined with public_read_only because a public bucket policy activates RestrictPublicBuckets, which blocks all cross-account access.
EOF

  validation {
    condition     = alltrue([for acct in var.trusted_account_ids : contains(["read", "write"], acct.access_level)])
    error_message = "access_level must be either \"read\" or \"write\"."
  }

  validation {
    condition     = alltrue([for acct in var.trusted_account_ids : can(regex("^[0-9]{12}$", acct.account_id))])
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}
