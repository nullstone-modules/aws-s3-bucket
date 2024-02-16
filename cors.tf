resource "aws_s3_bucket_cors_configuration" "example" {
  count = length(var.cors_origins) > 0 && length(var.cors_methods) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = var.cors_methods
    allowed_origins = var.cors_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
