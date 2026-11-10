# ------------------------------------------------------------------------------
# Protected Pipeline Bucket & Object (gs://available-only-to-github-pipeline)
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "pipeline_bucket" {
  name                        = var.protected_bucket_name
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  labels = {
    managed_by = "terraform"
    purpose    = "github-wif-pipeline-validation"
  }
}

resource "google_storage_bucket_object" "helloworld" {
  name         = var.helloworld_object_name
  bucket       = google_storage_bucket.pipeline_bucket.name
  content      = var.helloworld_object_content
  content_type = "text/plain; charset=utf-8"
}

# ------------------------------------------------------------------------------
# Isolated Remote State Bucket for the GitOps Repository
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "gitops_tfstate" {
  name                        = var.gitops_state_bucket_name
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  labels = {
    managed_by = "terraform"
    purpose    = "jingle-bells-tfstate"
  }
}
