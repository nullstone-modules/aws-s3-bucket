output "region" {
  value = data.aws_region.this.name
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "string ||| The ARN of the created S3 bucket."
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "string ||| The name of the created S3 bucket."
}

output "deployer" {
  value = {
    name       = aws_iam_user.deployer.name
    access_key = aws_iam_access_key.deployer.id
    secret_key = aws_iam_access_key.deployer.secret
  }

  description = "object({ name: string, access_key: string, secret_key: string }) ||| An AWS User with explicit privilege to deploy to the S3 bucket."

  sensitive = true
}
