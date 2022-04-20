# aws-s3-bucket

AWS S3 bucket datastore

## Security & Compliance

Security scanning is graciously provided by Bridgecrew. Bridgecrew is the leading fully hosted, cloud-native solution providing continuous Terraform security and compliance.

[![Infrastructure Security](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/general)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=INFRASTRUCTURE+SECURITY)
[![CIS AWS V1.3](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/cis_aws_13)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=CIS+AWS+V1.3)
[![PCI-DSS V3.2](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/pci)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=PCI-DSS+V3.2)
[![NIST-800-53](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/nist)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=NIST-800-53)
[![ISO27001](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/iso)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=ISO27001)
[![SOC2](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/soc2)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=SOC2)
[![HIPAA](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/hipaa)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=HIPAA)

## Inputs

- `versioning: bool`
    - Use the versioning feature of S3 to keep multiple versions of each object stored in your bucket.
      With versioning you can list, retrieve, and restore multiple versions of your objects.
    - Default: `true`

- `server_side_encryption: bool`
    - Encrypts all data at the object level as it is being written to S3, automatically decrypts it as you access it.
      The way you access objects (presigned URLs, listing objects, and retrieving objects) all works the same way as if they were not encrypted.
    - Default: `true`

## Outputs

- `db_arn` - AWS ARN for the created S3 bucket.
- `db_protocol` - URI Protocol (always `s3`)
- `db_hostname` - The hostname of the created s3 bucket.
- `db_port` - The port of the created s3 bucket (always blank).
