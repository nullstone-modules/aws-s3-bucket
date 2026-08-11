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
| `trusted_account_ids` | list(object)   | `[]`       | AWS accounts allowed to read or write this bucket, each with an access level of `read` or `write`. See [Sharing across AWS accounts](#sharing-across-aws-accounts).                                                                       |
| `expiration_days`         | number           | `0`        | Permanently delete objects this many days after they are created. `0` never expires. See [Lifecycle](#lifecycle).                                                                                                                        |
| `noncurrent_version_expiration_days` | number | `0`      | Delete old versions of an object this many days after they stop being current. `0` keeps every version forever.                                                                                                                          |
| `noncurrent_versions_to_keep` | number      | `0`        | Always retain at least this many of the most recent noncurrent versions, even once they are older than the expiration window. Requires `noncurrent_version_expiration_days`.                                                              |
| `abort_incomplete_multipart_upload_days` | number | `0`   | Abort multipart uploads that have not completed this many days after starting, and delete the parts already uploaded. `0` leaves them in place.                                                                                           |
| `transition_to_ia_days`   | number           | `0`        | Move objects to Standard-Infrequent Access this many days after they are created. Must be `0` or at least `30`.                                                                                                                           |
| `transition_to_glacier_days` | number        | `0`        | Move objects to Glacier Instant Retrieval this many days after they are created. `0` never transitions.                                                                                                                                   |
| `expire_delete_markers`   | boolean          | `false`    | Remove delete markers that have no object versions left underneath them.                                                                                                                                                                 |

## Outputs
| Name                      | Description                                                                    |
| ------------------------- |--------------------------------------------------------------------------------|
| `db_arn`                  | The ARN (Amazon Resource Name) that uniquely identifies the created S3 bucket. |
| `db_hostname`             | The name of the created s3 bucket.                                             |
| `db_port`                 | This port of the created s3 bucket (always blank).                             |
| `db_protocol`             | URI Protocol (always `s3`)                                                     |
| `db_region`               | The region of the created S3 bucket.                                           |
| `aws_account_id`          | The AWS account that owns this bucket. S3 bucket ARNs contain no account ID, so consumers that need it rely on this output. |
| `kms_key_arn`             | The customer-managed KMS key encrypting this bucket, passed to capabilities so they can grant decryption. Blank unless a key is connected. |

## Connections
| Name                      | Contract           | Optional | Description                                                                    |
| ------------------------- |--------------------|----------|--------------------------------------------------------------------------------|
| `kms_key`                 | `datastore/aws/kms` | yes      | A customer-managed KMS key to encrypt this bucket with. Required to share an encrypted bucket across accounts. |

---

## How Do I Use This?
Connect this S3 bucket to your applications using a capability.
The capability will set up the correct access privileges and inject the connection information into your applications via ENV variables.
This S3 bucket can be connected to many applications in order to share files between the applications.

---

## Lifecycle

By default nothing in this bucket ever ages out. The lifecycle variables let you expire objects, clean up old versions, reclaim failed uploads, and move data to cheaper storage classes. Every one of them is off by default, so a bucket that sets none of them has no lifecycle configuration at all.

### Versioning is why this matters

`versioning` defaults to **on**, which means every overwrite of an object leaves the previous copy behind as a noncurrent version, and every delete leaves a delete marker. Neither is visible when you list the bucket, and both are billed as storage indefinitely. A bucket that has been overwriting the same objects for a year is paying for a year of copies.

`noncurrent_version_expiration_days` is the rule that reclaims them:

```hcl
noncurrent_version_expiration_days = 30
noncurrent_versions_to_keep        = 3
```

That expires versions 30 days after they stop being current, while always keeping the 3 most recent regardless of age — so there is still something to roll back to for an object that has not changed in months. `noncurrent_versions_to_keep` on its own does nothing and fails at plan time; it only modifies the age-based rule.

These rules apply to whatever noncurrent versions exist, not to whether versioning is currently on. Turning `versioning` off **suspends** it rather than removing history, so versions accumulated while it was on stay until a rule expires them.

`expiration_days` behaves differently than it looks on a versioned bucket: it deletes the *current* version and leaves a delete marker, rather than removing the object outright. The versions underneath are then cleaned up by `noncurrent_version_expiration_days`, and the leftover markers by `expire_delete_markers`. On a versioned bucket, expiring objects usually means setting all three.

### Storage classes

`transition_to_ia_days` requires at least 30 days — S3 will not move an object to Standard-IA before it has spent 30 days in Standard. `transition_to_glacier_days` uses **Glacier Instant Retrieval**, not Glacier Flexible Retrieval, so objects stay readable in milliseconds with no restore step and applications reading the bucket keep working. The tradeoff is that transitioned objects are billed for a minimum of 90 days, which makes it a poor fit for data that expires sooner than that.

Transitions must move objects forward and expiration must come last: `transition_to_ia_days` < `transition_to_glacier_days` < `expiration_days`. Violations fail at plan time rather than as an S3 error during apply.

Objects under 128KB are not transitioned. This is an S3 default the module pins explicitly, so it cannot shift under a provider upgrade.

### Incomplete uploads

`abort_incomplete_multipart_upload_days` reclaims the parts left behind by large uploads that failed partway through. These are invisible when listing the bucket but are billed as storage, and nothing removes them otherwise. Set it above the longest upload you expect to legitimately take.

### This resource is authoritative

Setting any lifecycle variable makes this module the sole owner of the bucket's lifecycle configuration. Rules added by hand in the AWS console or by another tool will be removed on the next apply.

---

## Sharing across AWS accounts
To let an application in a different AWS account use this bucket, add that account to `trusted_account_ids` with the access level it should get. The application then connects through an `aws-s3-access-point` datastore in its own account.

```hcl
trusted_account_ids = [
  { account_id = "111122223333", access_level = "read" },
  { account_id = "444455556666", access_level = "write" },
]
```

You grant trust **once per account, not once per application**. The consuming account creates and owns its own S3 access point, and decides which of its applications may use it. This bucket's policy simply delegates to the trusted account, so it never needs to change as applications come and go.

The level you set is a **ceiling**. The consuming account can narrow it further with its own access point policy or IAM policies, but it can never exceed what you grant here. `write` includes read.

The delegation statements name each trusted account's root as the principal. Because the principals are fixed, the statements are **not** considered public, so `block_public_policy` remains enabled.

The grant is to the **account**, not to its access points. AWS documents delegating with a `s3:DataAccessPointAccount` condition instead, but that key is only defined for the `accesspoint` and `accesspointobject` resource types (see the [Service Authorization Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_s3.html)) — never for `bucket` or `object`. S3 enforces this for object reads: a bucket policy statement conditioning `s3:GetObject` on it can never match, so the consumer can list the bucket and read tags while every `GetObject` fails with `no resource-based policy allows the s3:GetObject action`. No condition key S3 supports on bucket-typed resources can pin an account to its access points, so the trusted account could also reach the bucket directly — its own IAM policies remain the gate on which principals actually can.

`read` grants `GetObject` plus object versions and tagging. `write` adds `PutObject`, the delete actions, and multipart uploads. Both grant bucket listing (`ListBucket`, `ListBucketVersions`), since a read-only consumer still needs to enumerate objects. `GetBucketLocation` and `ListBucketMultipartUploads` are not granted — neither can be addressed through an access point at all.

Accounts are grouped by level, so the bucket policy holds at most three delegation statements no matter how many accounts you list. That matters because bucket policies are capped at 20KB. Listing the same account at both levels is harmless — grants are additive, so it ends up with write.

### Limitations
`trusted_account_ids` cannot be combined with `public_read_only`. A public bucket policy activates `RestrictPublicBuckets`, which blocks all cross-account access — including non-public delegation to specific accounts. Setting both fails at apply time rather than silently at runtime.

### Encryption

By default this bucket is encrypted with the AWS-managed `aws/s3` KMS key, whose key policy is immutable and grants only the owning account. Objects encrypted with it **cannot be read from another account** under any configuration — the access point is created successfully and listing works, but every `GetObject` fails on decrypt.

To share an encrypted bucket, connect an `aws-kms-key` datastore and list the same accounts on it:

```yaml
datastores:
  usage-stats-archiver:
    module: nullstone/aws-s3-bucket
    connections:
      kms_key: usage-stats-key
    vars:
      trusted_account_ids:
        - { account_id: "490532603356", access_level: read }

  usage-stats-key:
    module: nullstone/aws-kms-key
    vars:
      trusted_accounts:
        - { account_id: "490532603356", access_level: read }
      via_services: ["s3.us-east-1.amazonaws.com"]
```

The two lists are deliberately separate. A key can back more than one bucket, and the bucket's workspace cannot write the key's policy, so each side declares its own trust. If they drift, S3 allows the request and KMS refuses it. A `check` block warns at plan time when a bucket has `trusted_account_ids` but no connected key.

Setting `server_side_encryption = false` also works and is simpler: S3 still applies SSE-S3 (AES256) by default, which carries no key policy and crosses accounts freely. You lose the KMS audit trail and per-key revocation, not encryption at rest.

**Switching an existing bucket to a customer-managed key is forward-only.** Default encryption applies at write time, so objects already stored keep the key they were written with — AWS never re-encrypts in place. Objects written under `aws/s3` stay unreadable cross-account even after a key is connected. To migrate them, copy in place from the owning account (`aws s3 cp s3://bucket/ s3://bucket/ --recursive --sse aws:kms --sse-kms-key-id <arn>`), and note that with `versioning` on this writes a new version of every object while the old, still-unreadable versions remain billable until a lifecycle rule expires them.

**In-account reads and writes are not interrupted.** A customer-managed key would normally require every caller to hold `kms:Decrypt`, breaking apps that were working a moment earlier. `aws-kms-key` prevents that with its `allow_account_use` setting, on by default, which reproduces the statement AWS-managed keys carry. Apps in this account keep working the instant the key is connected, with no IAM change and no re-apply. If you set `allow_account_use = false`, grant each app the key **before** connecting it, or the first object written under the new key becomes unreadable.
