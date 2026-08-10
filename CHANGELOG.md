# 0.3.0 (Aug 10, 2026)
* Added `trusted_account_ids` to share this bucket with other AWS accounts through S3 access points.
* The bucket policy is now created whenever any statement applies, not only for `public_read_only`. `aws_s3_bucket_policy.public_read_only` was renamed to `aws_s3_bucket_policy.this`; a `moved` block handles the state migration.
* `public_read_only` and `trusted_account_ids` are mutually exclusive and now fail at apply time rather than silently at runtime.

# 0.2.0 (Jun 25, 2026)
* Upgraded `ns` provider.
* Switched to `aws_tags` for proper resource attribution.
* Added `aws_account_id` to outputs.

# 0.1.14 (Mar 20, 2025)
* Added db_region to outputs.
