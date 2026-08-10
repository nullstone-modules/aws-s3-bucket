// Optional so that buckets without a key connected keep using the AWS-managed `aws/s3` key exactly
// as before. Connecting a key is only necessary when something outside this account has to decrypt,
// because the key policy of `aws/s3` is immutable and can never be shared.
data "ns_connection" "kms_key" {
  name     = "kms_key"
  contract = "datastore/aws/kms"
  optional = true
}

locals {
  kms_key_arn = try(data.ns_connection.kms_key.outputs.kms_key_arn, "")

  // Connecting a key implies the bucket should be encrypted with it, even if server_side_encryption
  // was left off.
  encryption_enabled = var.server_side_encryption || local.kms_key_arn != ""
}

// Delegating the bucket to another account's access points does nothing for the objects themselves
// if they are encrypted under a key that account can never be granted. The request gets past every
// S3 policy and then fails on KMS, which reports AccessDenied on the key rather than on the bucket.
check "crossaccount_encryption" {
  assert {
    condition     = !(length(var.trusted_access_points) > 0 && var.server_side_encryption && local.kms_key_arn == "")
    error_message = "This bucket is shared with other accounts through trusted_access_points, but it is encrypted with the AWS-managed `aws/s3` key, which cannot be shared. Those accounts will be able to list the bucket and will get AccessDenied on every object. Connect an aws-kms-key datastore to this bucket, or set server_side_encryption to false."
  }
}
