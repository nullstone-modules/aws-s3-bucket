# aws-s3-bucket

AWS S3 bucket datastore

## Inputs

- `versioning` - Enable versioning of objects in the S3 store.
- `server_side_encryption` - Enable encryption of objects as they are written in the S3 store. Access the objects the same way, decryption occurs automatically. 

## Outputs

- `region` - The region of the created S3 bucket.
- `bucket_arn` - The ARN of the created S3 bucket.
- `bucket_name` - The name of the created S3 bucket.
