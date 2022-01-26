output "region" {
  value       = data.aws_region.this.name
  description = "string ||| The AWS region that the S3 bucket will be created in."
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "string ||| The ARN of the created S3 bucket."
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "string ||| The name of the created S3 bucket."
}
