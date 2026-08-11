# 0.4.0 (Aug 11, 2026)
* Delegation statements now name each trusted account's root as the principal instead of matching on `s3:DataAccessPointAccount`.
* **Breaking:** Renamed `var.trusted_access_points` to `var.trusted_account_ids` as part of the fix to cross-account access.

# 0.3.3 (Aug 10, 2026)
* Added an optional `kms_key` connection to encrypt this bucket with a customer-managed KMS key from the `aws-kms-key` module.
* Added a `check` that warns when `trusted_access_points` is set on a bucket still encrypted with `aws/s3`, which lists successfully and then fails on every object.

# 0.3.2 (Aug 10, 2026)
* Removed invalid s3 actions that are incompatible with access point IAM conditions.

# 0.3.1 (Aug 10, 2026)
* Delegation statements are split by resource scope. `s3:DataAccessPointAccount` only applies to access point resource types, so mixing bucket-scoped and object-scoped actions in one statement is rejected as `MalformedPolicy`.

# 0.3.0 (Aug 10, 2026)
* Added `trusted_access_points` to share this bucket with other AWS accounts through S3 access points, each granted `read` or `write`.
* The bucket policy is now created whenever any statement applies, not only for `public_read_only`. `aws_s3_bucket_policy.public_read_only` was renamed to `aws_s3_bucket_policy.this`; a `moved` block handles the state migration.
* `public_read_only` and `trusted_access_points` are mutually exclusive and now fail at apply time rather than silently at runtime.

# 0.2.0 (Aug 10, 2026)
* Upgraded `ns` provider.
* Switched to `aws_tags` for proper resource attribution.
* Added `aws_account_id` to outputs.

# 0.1.14 (Mar 20, 2025)
* Added db_region to outputs.
