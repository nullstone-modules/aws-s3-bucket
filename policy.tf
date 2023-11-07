resource "aws_s3_bucket_policy" "public_read_access" {
  count = var.public_read_only ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public-read-only.json
}

data "aws_iam_policy_document" "public-read-only" {
  statement {
    sid       = "AllowEveryoneReadOnlyAccess"
    effect    = "Allow"
    principal = "*"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
  }
}
