# Random suffix persisted in remote state for collision-free naming
resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  common_labels = {
    managed_by = "github-wif-gitops"
    repository = "jingle-bells"
  }
}

# ------------------------------------------------------------------------------
# 1. Cloud Pub/Sub: Event Topic, Dead-Letter Topic & Subscription
# ------------------------------------------------------------------------------
resource "google_pubsub_topic" "gitops_events" {
  name                       = "jingle-bells-events-${random_id.suffix.hex}"
  message_retention_duration = "86400s"
  labels                     = local.common_labels
}

resource "google_pubsub_topic" "gitops_dlq" {
  name   = "jingle-bells-dlq-${random_id.suffix.hex}"
  labels = local.common_labels
}

resource "google_pubsub_subscription" "gitops_events_sub" {
  name                 = "jingle-bells-events-sub-${random_id.suffix.hex}"
  topic                = google_pubsub_topic.gitops_events.id
  ack_deadline_seconds = 20

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.gitops_dlq.id
    max_delivery_attempts = 5
  }

  labels = local.common_labels
}

# ------------------------------------------------------------------------------
# 2. Secret Manager: Secret + Version storing verified GCS object attestation
# ------------------------------------------------------------------------------
resource "google_secret_manager_secret" "helloworld_attestation" {
  secret_id = "jingle-bells-attestation-${random_id.suffix.hex}"
  labels    = local.common_labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "helloworld_attestation_v1" {
  secret = google_secret_manager_secret.helloworld_attestation.id
  secret_data = jsonencode({
    source_uri     = "gs://${var.target_bucket}/${var.target_object}"
    content        = data.google_storage_bucket_object_content.helloworld.content
    content_sha256 = sha256(data.google_storage_bucket_object_content.helloworld.content)
  })
}

# ------------------------------------------------------------------------------
# 3. BigQuery: Telemetry Dataset & Pipeline Verification Table
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset" "gitops_telemetry" {
  dataset_id                 = "jingle_bells_telemetry_${random_id.suffix.hex}"
  friendly_name              = "Jingle Bells GitOps Telemetry"
  description                = "Dataset managed via GitHub Actions WIF Service Account"
  location                   = var.region
  delete_contents_on_destroy = true
  labels                     = local.common_labels
}

resource "google_bigquery_table" "validation_runs" {
  dataset_id          = google_bigquery_dataset.gitops_telemetry.dataset_id
  table_id            = "validation_runs"
  deletion_protection = false
  labels              = local.common_labels

  schema = jsonencode([
    {
      name = "run_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "wif_service_account"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "gcs_object_uri"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "verified_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])
}

# ------------------------------------------------------------------------------
# 4. Artifact Registry: Regional Docker Repository
# ------------------------------------------------------------------------------
resource "google_artifact_registry_repository" "containers" {
  location               = var.region
  repository_id          = "jingle-bells-docker-${random_id.suffix.hex}"
  description            = "Container repository deployed by GitHub Actions WIF GitOps pipeline"
  format                 = "DOCKER"
  cleanup_policy_dry_run = true
  labels                 = local.common_labels
}
