output "workload_identity_provider" {
  description = "Full resource name of the GitHub OIDC Workload Identity Provider."
  value       = google_iam_workload_identity_pool_provider.github_oidc.name
}

output "plan_service_account_email" {
  description = "Read-only WIF service account for Terraform plan and GCS validation."
  value       = google_service_account.tf_plan.email
}

output "apply_service_account_email" {
  description = "Main-branch WIF service account for Terraform apply."
  value       = google_service_account.tf_apply.email
}

output "protected_bucket_url" {
  description = "GCS URL of the protected bucket."
  value       = google_storage_bucket.pipeline_bucket.url
}

output "helloworld_gs_uri" {
  description = "Full gs:// URI of the helloworld object."
  value       = "${google_storage_bucket.pipeline_bucket.url}/${google_storage_bucket_object.helloworld.name}"
}

output "gitops_tfstate_bucket" {
  description = "Dedicated GCS bucket for jingle-bells Terraform remote state."
  value       = google_storage_bucket.gitops_tfstate.name
}
