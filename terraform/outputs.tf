output "active_wif_caller_email" {
  description = "Email of the WIF Service Account executing Terraform."
  value       = data.google_client_openid_userinfo.caller.email
}

output "verified_object_uri" {
  description = "GCS URI of the validated object."
  value       = terraform_data.verified_helloworld_object.output.uri
}

output "verified_content_sha256" {
  description = "SHA-256 digest of the object contents."
  value       = terraform_data.verified_helloworld_object.output.content_sha256
}

output "helloworld_content" {
  description = "Contents read from gs://available-only-to-github-pipeline/helloworld.txt."
  value       = data.google_storage_bucket_object_content.helloworld.content
}

output "pubsub_topic_id" {
  description = "Managed Cloud Pub/Sub event topic ID."
  value       = google_pubsub_topic.gitops_events.id
}

output "pubsub_subscription_id" {
  description = "Managed Cloud Pub/Sub subscription ID."
  value       = google_pubsub_subscription.gitops_events_sub.id
}

output "secret_manager_secret_id" {
  description = "Managed Secret Manager attestation secret ID."
  value       = google_secret_manager_secret.helloworld_attestation.id
}

output "bigquery_table_fqn" {
  description = "Managed BigQuery telemetry table."
  value       = "${google_bigquery_dataset.gitops_telemetry.project}.${google_bigquery_dataset.gitops_telemetry.dataset_id}.${google_bigquery_table.validation_runs.table_id}"
}

output "artifact_registry_repo" {
  description = "Managed Artifact Registry Docker repository URI."
  value       = "${google_artifact_registry_repository.containers.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.name}"
}
