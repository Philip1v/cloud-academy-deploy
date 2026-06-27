# Cloud Academy – React Deployment to AWS with Terraform & GitHub Actions

## Project Overview

This project provisions a production-like deployment pipeline for a React-based
marketing website. Infrastructure is defined as code with **Terraform**, the
application is hosted privately on **Amazon S3**, served globally through
**Amazon CloudFront**, and deployed automatically via a **GitHub Actions**
CI/CD pipeline. Authentication between GitHub and AWS uses **OIDC** — no
long-lived AWS access keys are stored anywhere. Every push to `main`
automatically builds and deploys the latest version of the site.

## Architecture Diagram

![Architecture](architecture.png)

The diagram shows two flows:

- **Deployment flow:** Developer → GitHub Repository → GitHub Actions → IAM Role (OIDC) → S3 Bucket
- **User request flow:** Browser → CloudFront → S3 Bucket

## AWS Component Descriptions

**Amazon S3** — Stores the compiled React build output (the contents of
`app/dist/`). The bucket is fully private: all public access is blocked and it
is never exposed directly to the internet. It also stores the Terraform remote
state in a separate dedicated bucket.

**Amazon CloudFront** — A Content Delivery Network (CDN) that caches the site
at edge locations worldwide, giving users fast load times regardless of
location. It is the only entity allowed to read from the private S3 bucket, via
Origin Access Control (OAC). Serving through CloudFront (rather than S3
directly) provides HTTPS, global caching, and keeps the bucket private.

**IAM Role (OIDC)** — Lets GitHub Actions assume a role using a short-lived,
automatically rotated token instead of static access keys. GitHub presents a
signed JWT, AWS validates it against the registered OIDC provider, and issues
temporary credentials scoped only to this repository. This removes the risk of
leaked, long-lived credentials.

## Deployment Instructions

### Prerequisites

- An AWS account with permissions to create IAM, S3, and CloudFront resources
- Terraform >= 1.10 and the AWS CLI installed and configured
- A GitHub repository containing this project
- Node.js 20+

### 1. Bootstrap the Terraform state bucket (one-time, manual)

The bucket that stores Terraform state must exist before Terraform can use it:

```bash
aws s3api create-bucket \
  --bucket cloud-academy-tfstate-pi \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket cloud-academy-tfstate-pi \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket cloud-academy-tfstate-pi \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 2. Provision the infrastructure

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

CloudFront takes 5–15 minutes to reach `Deployed` status. After apply, note the
outputs: `s3_bucket_name`, `cloudfront_distribution_id`, and
`cloudfront_domain_name`.

### 3. Configure GitHub OIDC and secrets

- Register `token.actions.githubusercontent.com` as an IAM OIDC provider
  (audience `sts.amazonaws.com`).
- Create an IAM role with a trust policy scoped to this repository, and a
  permission policy granting S3 upload and CloudFront invalidation rights.
- In the GitHub repository, add these secrets under
  **Settings → Secrets and variables → Actions**:

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | ARN of the GitHub Actions IAM role |
| `AWS_REGION` | `us-east-1` |
| `S3_BUCKET_NAME` | `cloud-academy-prod-site-pi` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E280DEDGEKN1CE` |

### 4. Trigger a deployment

Push any change to `main`. The GitHub Actions workflow will build the app,
upload it to S3, and invalidate the CloudFront cache. The workflow can also be
run manually from the Actions tab via `workflow_dispatch`.

## Website URL

https://d1ximipxocvnsv.cloudfront.net