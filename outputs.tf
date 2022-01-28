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