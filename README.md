# Jingle Bells — Secure Terraform GitOps & GCS WIF Pipeline

GitOps Terraform repository wired to Google Cloud project **`gwx-sandbox`** via keyless **Workload Identity Federation (WIF)** following supply-chain and IAM security best practices.

## Repository Layout

- **`bootstrap/`** — Bootstrap Terraform configuration that provisions:
  - Protected GCS bucket **`gs://available-only-to-github-pipeline`** (Uniform Bucket-Level Access, Public Access Prevention `enforced`, Versioning, Soft Delete)
  - GCS object **`helloworld.txt`** with UTF-8 contents `"📙  😃  💁👌🎍"`
  - Dedicated remote state bucket **`gs://gwx-sandbox-jingle-bells-tfstate`**
  - Workload Identity Pool (`github-jingle-bells-pool`) & GitHub OIDC Provider (`github-oidc`) pinned to immutable `repository_owner_id`, `repository_id`, and `repository` claims
  - Two least-privilege WIF Service Accounts:
    - `jingle-bells-tf-plan@gwx-sandbox.iam.gserviceaccount.com` (viewer/reader roles across GCS, Pub/Sub, Secret Manager, BigQuery, and Artifact Registry + conditional `.tflock` lock permission)
    - `jingle-bells-tf-apply@gwx-sandbox.iam.gserviceaccount.com` (impersonation restricted strictly to `refs/heads/main`, scoped service admin roles)
- **`terraform/`** — GitOps-managed Terraform stack using remote GCS state that:
  - Verifies Terraform is executing under a GitHub WIF Service Account via `data.google_client_openid_userinfo` (`check "running_as_wif_service_account"`).
  - Reads `gs://available-only-to-github-pipeline/helloworld.txt` via WIF and asserts its exact contents (`"📙  😃  💁👌🎍"`).
  - Deploys multi-service GCP resources managed by the WIF Service Account:
    1. **Cloud Pub/Sub** event topic, dead-letter topic, and subscription
    2. **Secret Manager** secret & version storing the verified `helloworld.txt` SHA-256 attestation
    3. **BigQuery** dataset & `validation_runs` telemetry table
    4. **Artifact Registry** regional Docker repository
- **`.github/workflows/validate-gcs-object.yml`** — GitHub Actions workflow (`push`, `pull_request`, `workflow_dispatch`) that authenticates via WIF (`external_account`), verifies `gs://available-only-to-github-pipeline/helloworld.txt` exists, and validates its contents.
- **`.github/workflows/terraform-gitops.yml`** — Hardened GitOps Terraform pipeline verifying keyless WIF `external_account` credentials, running `plan` with `jingle-bells-tf-plan` on PRs, and running `apply` with `jingle-bells-tf-apply` on merges to `main`.
