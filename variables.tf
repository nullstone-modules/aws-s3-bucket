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

variable "expiration_days" {
  type        = number
  default     = 0
  description = <<EOF
Permanently delete objects this many days after they are created.
With versioning enabled, this deletes the current version and leaves a delete marker rather than removing the object outright; use noncurrent_version_expiration_days to reclaim the versions underneath it.
Set to 0 to never expire objects.
EOF

  validation {
    condition     = var.expiration_days >= 0
    error_message = "expiration_days cannot be negative. Use 0 to disable expiration."
  }
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 0
  description = <<EOF
Permanently delete old versions of an object this many days after they stop being the current version.
This only applies to buckets that have used versioning; with versioning off, no new noncurrent versions are created, but any left over from when it was on are still cleaned up.
Set to 0 to keep every version forever.
EOF

  validation {
    condition     = var.noncurrent_version_expiration_days >= 0
    error_message = "noncurrent_version_expiration_days cannot be negative. Use 0 to disable noncurrent version expiration."
  }
}

variable "noncurrent_versions_to_keep" {
  type        = number
  default     = 0
  description = <<EOF
Always retain at least this many of the most recent noncurrent versions, even once they are older than noncurrent_version_expiration_days.
This is a floor on how far back you can restore an object, useful when the expiration window alone would leave nothing to roll back to.
Requires noncurrent_version_expiration_days. Set to 0 to expire purely by age.
EOF

  validation {
    condition     = var.noncurrent_versions_to_keep >= 0 && var.noncurrent_versions_to_keep <= 100
    error_message = "noncurrent_versions_to_keep must be between 0 and 100. S3 does not accept a larger value."
  }
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  default     = 0
  description = <<EOF
Abort multipart uploads that have not completed this many days after they were started, and delete the parts already uploaded.
Failed or interrupted large uploads leave their parts behind indefinitely, and those parts are billed even though they are not visible when listing the bucket.
Set to 0 to leave incomplete uploads in place.
EOF

  validation {
    condition     = var.abort_incomplete_multipart_upload_days >= 0
    error_message = "abort_incomplete_multipart_upload_days cannot be negative. Use 0 to leave incomplete multipart uploads in place."
  }
}

variable "transition_to_ia_days" {
  type        = number
  default     = 0
  description = <<EOF
Move objects to the Standard-Infrequent Access storage class this many days after they are created.
Objects stay immediately readable; storage costs less and retrieval costs more, so this suits data that is kept but rarely read.
Must be at least 30 if set. Set to 0 to never transition.
EOF

  validation {
    condition     = var.transition_to_ia_days == 0 || var.transition_to_ia_days >= 30
    error_message = "transition_to_ia_days must be 0 or at least 30. S3 requires an object to spend 30 days in Standard before it can move to Standard-IA."
  }
}

variable "transition_to_glacier_days" {
  type        = number
  default     = 0
  description = <<EOF
Move objects to the Glacier Instant Retrieval storage class this many days after they are created.
Objects remain readable in milliseconds with no restore step, so applications reading the bucket keep working; storage is cheaper still and retrieval costs more again.
Objects are billed for a minimum of 90 days once transitioned, so this is a poor fit for data that expires sooner than that.
Set to 0 to never transition.
EOF

  validation {
    condition     = var.transition_to_glacier_days >= 0
    error_message = "transition_to_glacier_days cannot be negative. Use 0 to disable the transition."
  }
}

variable "expire_delete_markers" {
  type        = bool
  default     = false
  description = <<EOF
Remove delete markers that have no object versions left underneath them.
When an object in a versioned bucket is deleted, S3 leaves a marker behind; once the versions below it expire, the marker remains and still slows down listing the bucket.
This only affects markers with nothing left underneath, so it never makes a deleted object reappear.
EOF
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
