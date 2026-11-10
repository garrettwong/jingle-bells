# Inspect the active GCP identity executing Terraform
data "google_client_openid_userinfo" "caller" {}

# Verify Terraform is executing under one of the dedicated GitHub WIF Service Accounts
check "running_as_wif_service_account" {
  assert {
    condition = contains([
      "jingle-bells-tf-plan@${var.project_id}.iam.gserviceaccount.com",
      "jingle-bells-tf-apply@${var.project_id}.iam.gserviceaccount.com",
    ], data.google_client_openid_userinfo.caller.email)
    error_message = "Expected Terraform to run as a GitHub WIF Service Account, but active caller is '${data.google_client_openid_userinfo.caller.email}'."
  }
}

# Read the protected GCS object via the WIF Service Account
data "google_storage_bucket_object_content" "helloworld" {
  bucket = var.target_bucket
  name   = var.target_object
}

# Continuous assertion check verifying object existence and exact contents
check "helloworld_content_matches" {
  assert {
    condition     = data.google_storage_bucket_object_content.helloworld.content == var.expected_content
    error_message = "Object gs://${var.target_bucket}/${var.target_object} did not match expected contents '${var.expected_content}'."
  }
}

# Persist verified digest in GitOps remote state with a hard precondition gate
resource "terraform_data" "verified_helloworld_object" {
  input = {
    uri            = "gs://${var.target_bucket}/${var.target_object}"
    content_sha256 = sha256(data.google_storage_bucket_object_content.helloworld.content)
  }

  lifecycle {
    precondition {
      condition     = data.google_storage_bucket_object_content.helloworld.content == var.expected_content
      error_message = "Precondition failed: gs://${var.target_bucket}/${var.target_object} content mismatch."
    }
  }
}
