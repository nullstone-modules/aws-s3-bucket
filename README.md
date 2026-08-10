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
| `crossaccount_account_ids` | set(string)     | `[]`       | AWS account IDs allowed to reach this bucket through an S3 access point. See [Sharing across AWS accounts](#sharing-across-aws-accounts).                                                                                                                   |

## Outputs
| Name                      | Description                                                                    |
| ------------------------- |--------------------------------------------------------------------------------|
| `db_arn`                  | The ARN (Amazon Resource Name) that uniquely identifies the created S3 bucket. |
| `db_hostname`             | The name of the created s3 bucket.                                             |
| `db_port`                 | This port of the created s3 bucket (always blank).                             |
| `db_protocol`             | URI Protocol (always `s3`)                                                     |
| `db_region`               | The region of the created S3 bucket.                                           |
| `aws_account_id`          | The AWS account that owns this bucket. S3 bucket ARNs contain no account ID, so consumers that need it rely on this output. |

---

## How Do I Use This?
Connect this S3 bucket to your applications using a capability.
The capability will set up the correct access privileges and inject the connection information into your applications via ENV variables.
This S3 bucket can be connected to many applications in order to share files between the applications.

---

## Sharing across AWS accounts
To let an application in a different AWS account use this bucket, add that account's ID to `crossaccount_account_ids`. The application then connects through an `aws-s3-access-point` datastore in its own account.

You grant trust **once per account, not once per application**. The consuming account creates and owns its own S3 access point, and decides which of its applications may use it. This bucket's policy simply delegates to any access point owned by a trusted account, so it never needs to change as applications come and go.

The delegation statement matches on `s3:DataAccessPointAccount`. Because the account ID is fixed, the statement is **not** considered public, so `block_public_policy` remains enabled.

### Limitations
`crossaccount_account_ids` cannot be combined with `public_read_only`. A public bucket policy activates `RestrictPublicBuckets`, which blocks all cross-account access — including non-public delegation to specific accounts. Setting both fails at apply time rather than silently at runtime.

**Encryption is not yet handled.** While `server_side_encryption` is on, this bucket uses the AWS-managed `aws/s3` KMS key, whose key policy is immutable. Objects encrypted with it **cannot be read from another account** under any configuration — the access point will be created successfully and listing will work, but every `GetObject` fails on decrypt. Until this module supports an encryption mode that works across accounts, cross-account sharing is only usable with `server_side_encryption = false`.
