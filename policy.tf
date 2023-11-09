resource "aws_s3_bucket_policy" "public_read_only" {
  count = var.public_read_only ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public_read_only.json
}

data "aws_iam_policy_document" "public_read_only" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}
