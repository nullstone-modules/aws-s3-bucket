# S3 Bucket
#### nullstone/aws-s3-bucket

---

## Security & Compliance

Security scanning is graciously provided by Bridgecrew. Bridgecrew is the leading fully hosted, cloud-native solution providing continuous Terraform security and compliance.

[![Infrastructure Security](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/general)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=INFRASTRUCTURE+SECURITY)
[![CIS AWS V1.3](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/cis_aws_13)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=CIS+AWS+V1.3)
[![PCI-DSS V3.2](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/pci)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=PCI-DSS+V3.2)
[![NIST-800-53](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/nist)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=NIST-800-53)
[![ISO27001](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/iso)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=ISO27001)
[![SOC2](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/soc2)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=SOC2)
[![HIPAA](https://www.bridgecrew.cloud/badges/github/nullstone-modules/aws-s3-bucket/hipaa)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=nullstone-modules%2Faws-s3-bucket&benchmark=HIPAA)

## What Does This Module Do?
Creates an S3 bucket within your AWS account and outputs the information needed in order to connect to the bucket.

---

## When Should I Use This?
S3 buckets are great for storing files or data of any kind. Connecting S3 buckets to your applications allows you to very easily
save and retrieve files without having to think about persistence. For more information about S3 buckets, please read the <a href="https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html" target="_blank">AWS S3 Guide</a>.

---

## Parameters
| Name                      | Type             | Default    | Description                                                                                                                                                                                                                                                |
| ------------------------- | ---------------- |------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `server_side_encryption`  | boolean          | `true`     | Encrypts all data at the object level as it is being written to S3, automatically decrypts it as you access it. The way you access objects (presigned URLs, listing objects, and retrieving objects) all works the same way as if they were not encrypted. |
| `versioning`              | boolean          | `false`    | Use the versioning feature of S3 to keep multiple versions of each object stored in your bucket. With versioning you can list, retrieve, and restore multiple versions of your objects.                                                                    |
| `public_read_only`        | boolean          | `false`    | If toggled on, the contents of this S3 bucket will be made publicly accessible. Public access will be read-only.                                                                                                                                           |
| `cors_orgins`             | list(string)     | `[]`       | A set of origins that are allowed to make GET requests to this S3 bucket.                                                                                                                                                                                  |
| `cors_methods`            | list(string)     | `["GET"]`  | A set of HTTP verbs that are allowed to be used when making CORS requests to this S3 bucket.                                                                                                                                                               |

## Outputs
| Name                      | Description                                                                    |
| ------------------------- |--------------------------------------------------------------------------------|
| `db_arn`                  | The ARN (Amazon Resource Name) that uniquely identifies the created S3 bucket. |
| `db_hostname`             | The name of the created s3 bucket.                                             |
| `db_port`                 | This port of the created s3 bucket (always blank).                             |
| `db_protocol`             | URI Protocol (always `s3`)                                                     |

---

## How Do I Use This?
Connect this S3 bucket to your applications using a capability.
The capability will set up the correct access privileges and inject the connection information into your applications via ENV variables.
This S3 bucket can be connected to many applications in order to share files between the applications.
