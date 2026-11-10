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
