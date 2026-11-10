# ------------------------------------------------------------------------------
# Workload Identity Federation Pool & OIDC Provider for GitHub Actions
# ------------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-jingle-bells-pool"
  display_name              = "GitHub Actions (jingle-bells)"
  description               = "OIDC federation pool for garrettwong/jingle-bells GitOps workflows"
}

resource "google_iam_workload_identity_pool_provider" "github_oidc" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub Actions OIDC"
  description                        = "Pinned to garrettwong/jingle-bells by owner ID, repo ID, and repo name"

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.actor"               = "assertion.actor"
    "attribute.repository"          = "assertion.repository"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner"    = "assertion.repository_owner"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
    "attribute.ref"                 = "assertion.ref"
    "attribute.workflow_ref"        = "assertion.job_workflow_ref"
  }

  # Security best practice: pin to immutable numeric IDs + repository full name
  # so renamed orgs/repos or sibling repositories cannot exchange OIDC tokens.
  attribute_condition = <<-EOT
    assertion.repository_owner_id == "${var.github_owner_id}" &&
    assertion.repository_id == "${var.github_repo_id}" &&
    assertion.repository == "${var.github_repo}"
  EOT

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ------------------------------------------------------------------------------
# Least-Privilege WIF Service Accounts (Plan/Validate vs. Apply Separation)
# ------------------------------------------------------------------------------

# 1. Read-Only Plan & Bucket Validation Service Account (PRs, workflow_dispatch, main)
resource "google_service_account" "tf_plan" {
  project      = var.project_id
  account_id   = "jingle-bells-tf-plan"
  display_name = "GitHub GitOps Plan & Validate SA (jingle-bells)"
  description  = "Read-only WIF service account for Terraform plan and GCS object validation"
}

# 2. Apply Service Account (Strictly restricted to refs/heads/main)
resource "google_service_account" "tf_apply" {
  project      = var.project_id
  account_id   = "jingle-bells-tf-apply"
  display_name = "GitHub GitOps Apply SA (jingle-bells)"
  description  = "Protected main-branch WIF service account for Terraform apply"
}

# Allow workflows in garrettwong/jingle-bells to impersonate the read-only plan/validate SA
resource "google_service_account_iam_member" "wif_plan_binding" {
  service_account_id = google_service_account.tf_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Allow ONLY refs/heads/main in garrettwong/jingle-bells to impersonate the apply SA
resource "google_service_account_iam_member" "wif_apply_binding" {
  service_account_id = google_service_account.tf_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.ref/refs/heads/main"
}

# ------------------------------------------------------------------------------
# Least-Privilege Bucket IAM Bindings
# ------------------------------------------------------------------------------

# Grant read-only object access on gs://available-only-to-github-pipeline to both pipeline SAs
resource "google_storage_bucket_iam_member" "pipeline_bucket_reader_plan" {
  bucket = google_storage_bucket.pipeline_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.tf_plan.email}"
}

resource "google_storage_bucket_iam_member" "pipeline_bucket_reader_apply" {
  bucket = google_storage_bucket.pipeline_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# State bucket access: read-only on .tfstate for plan SA (+ conditional lock on .tflock), full state admin for apply SA
resource "google_storage_bucket_iam_member" "tfstate_reader_plan" {
  bucket = google_storage_bucket.gitops_tfstate.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.tf_plan.email}"
}

resource "google_storage_bucket_iam_member" "tfstate_lock_plan" {
  bucket = google_storage_bucket.gitops_tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_plan.email}"

  condition {
    title       = "allow_tflock_only"
    description = "Allow plan SA to create and delete .tflock files without write access to .tfstate"
    expression  = "resource.name.endsWith(\".tflock\")"
  }
}

resource "google_storage_bucket_iam_member" "tfstate_admin_apply" {
  bucket = google_storage_bucket.gitops_tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# ------------------------------------------------------------------------------
# Least-Privilege Project IAM Bindings for Managed GCP Resources
# (Pub/Sub, Secret Manager, BigQuery, Artifact Registry)
# ------------------------------------------------------------------------------
locals {
  plan_project_roles = toset([
    "roles/pubsub.viewer",
    "roles/secretmanager.viewer",
    "roles/secretmanager.secretAccessor",
    "roles/bigquery.metadataViewer",
    "roles/artifactregistry.reader",
  ])

  apply_project_roles = toset([
    "roles/pubsub.admin",
    "roles/secretmanager.admin",
    "roles/bigquery.admin",
    "roles/artifactregistry.admin",
  ])
}

resource "google_project_iam_member" "tf_plan_resource_readers" {
  for_each = local.plan_project_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_plan.email}"
}

resource "google_project_iam_member" "tf_apply_resource_admins" {
  for_each = local.apply_project_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}
