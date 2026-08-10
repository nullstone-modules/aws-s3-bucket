output "db_arn" {
  value       = aws_s3_bucket.this.arn
  description = "string ||| The ARN of the created S3 bucket."
}

output "db_protocol" {
  value       = "s3"
  description = "string ||| The protocol used to connect to the s3 bucket."
}

output "db_hostname" {
  value       = aws_s3_bucket.this.bucket
  description = "string ||| The name of the created S3 bucket."
}

output "db_port" {
  value       = ""
  description = "string ||| The port for s3 buckets is blank."
}

output "db_region" {
  value       = aws_s3_bucket.this.region
  description = "string ||| The region of the created S3 bucket."
}

output "kms_key_arn" {
  value       = local.kms_key_arn
  description = "string ||| The ARN of the customer-managed KMS key encrypting this bucket, passed to capabilities so they can grant decryption. Blank when the bucket is unencrypted or uses the AWS-managed `aws/s3` key, neither of which a capability can grant."
}

output "aws_account_id" {
  value       = data.aws_caller_identity.this.account_id
  description = "string ||| The AWS account that owns this S3 bucket. S3 bucket ARNs contain no account ID, so consumers that need it (such as cross-account access points) rely on this output."
}
