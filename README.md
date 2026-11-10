# Jingle Bells — Secure Terraform GitOps & GCS WIF Pipeline

GitOps Terraform repository wired to Google Cloud project **`gwx-sandbox`** via keyless **Workload Identity Federation (WIF)** following supply-chain and IAM security best practices.

## Repository Layout

- **`bootstrap/`** — Bootstrap Terraform configuration that provisions:
  - Protected GCS bucket **`gs://available-only-to-github-pipeline`** (Uniform Bucket-Level Access, Public Access Prevention `enforced`, Versioning, Soft Delete)
  - GCS object **`helloworld.txt`** with UTF-8 contents `"📙  😃  💁👌🎍"`
  - Dedicated remote state bucket **`gs://gwx-sandbox-jingle-bells-tfstate`**
  - Workload Identity Pool (`github-jingle-bells-pool`) & GitHub OIDC Provider (`github-oidc`) pinned to immutable `repository_owner_id`, `repository_id`, and `repository` claims
  - Two least-privilege WIF Service Accounts:
    - `jingle-bells-tf-plan@gwx-sandbox.iam.gserviceaccount.com` (read-only object viewer on the protected bucket + read-only `.tfstate` viewer with conditional `.tflock` lock permission)
    - `jingle-bells-tf-apply@gwx-sandbox.iam.gserviceaccount.com` (impersonation restricted strictly to `refs/heads/main`)
- **`terraform/`** — GitOps-managed Terraform stack using remote GCS state that reads `gs://available-only-to-github-pipeline/helloworld.txt` via WIF and asserts its exact contents (`"📙  😃  💁👌🎍"`).
- **`.github/workflows/validate-gcs-object.yml`** — GitHub Actions workflow (`push`, `pull_request`, `workflow_dispatch`) that authenticates via WIF as `jingle-bells-tf-plan`, verifies `gs://available-only-to-github-pipeline/helloworld.txt` exists, and validates its contents.
- **`.github/workflows/terraform-gitops.yml`** — Hardened GitOps Terraform pipeline running `plan` with the read-only WIF SA on PRs and `apply` with the `main`-restricted WIF SA on merges to `main`.

## Security Controls Implemented

1. **Zero Static Credentials**: OIDC token federation via `google-github-actions/auth` — no service account JSON keys exist.
2. **Claim-Pinned OIDC Provider**: `attribute_condition` enforces `repository_owner_id == "1182771"`, `repository_id == "1453269706"`, and `repository == "garrettwong/jingle-bells"`.
3. **Plan / Apply Identity Split**: Untrusted PRs can only assume `jingle-bells-tf-plan`, which cannot modify `.tfstate` (enforced via GCP IAM Condition `resource.name.endsWith(".tflock")`) or mutate infrastructure. Only `refs/heads/main` can assume `jingle-bells-tf-apply`.
4. **Supply-Chain Hardening**: All GitHub Actions are pinned to immutable 40-character commit SHAs, `persist-credentials: false` is set on `actions/checkout`, top-level `permissions: {}` enforces least privilege, and `.terraform.lock.hcl` cryptographic provider hashes are committed.
