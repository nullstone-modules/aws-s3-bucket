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

variable "trusted_access_points" {
  type = list(object({
    account_id   = string
    access_level = string
  }))
  default     = []
  description = <<EOF
A list of AWS accounts allowed to reach this bucket through an S3 access point, and how much access each one gets.
`account_id` is a 12-digit AWS account ID. `access_level` is either "read" or "write", where "write" also includes read.
Each listed account creates and owns its own access point, and decides which of its applications may use it, so you grant trust once per account, not once per application.
The level you grant here is a ceiling: the consuming account can narrow it further with its own access point policy, but it can never widen it.
This cannot be combined with public_read_only because a public bucket policy activates RestrictPublicBuckets, which blocks all cross-account access.
EOF

  validation {
    condition     = alltrue([for ap in var.trusted_access_points : contains(["read", "write"], ap.access_level)])
    error_message = "access_level must be either \"read\" or \"write\"."
  }

  validation {
    condition     = alltrue([for ap in var.trusted_access_points : can(regex("^[0-9]{12}$", ap.account_id))])
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}
