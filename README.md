# aws-s3-bucket

AWS S3 bucket datastore

## Inputs

## Outputs

- `region` - The region of the created S3 bucket.
- `bucket_arn` - The ARN of the created S3 bucket.
- `bucket_name` - The name of the created S3 bucket.
- `deployer` - An AWS User with explicit privilege to perform CRUD on the contents of the S3 bucket.
    - `name`       - Deployer username
    - `access_key` = Access Key ID
    - `secret_key` = Secret Access Key
