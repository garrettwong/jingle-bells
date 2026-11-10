variable "project_id" {
  description = "GCP Project ID hosting WIF and GCS resources."
  type        = string
  default     = "gwx-sandbox"
}

variable "region" {
  description = "Default GCP region for regional storage buckets."
  type        = string
  default     = "us-central1"
}

variable "github_owner" {
  description = "GitHub repository owner login."
  type        = string
  default     = "garrettwong"
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub user/org ID for OIDC claim pinning."
  type        = string
  default     = "1182771"
}

variable "github_repo" {
  description = "Full GitHub repository name (<owner>/<repo>)."
  type        = string
  default     = "garrettwong/jingle-bells"
}

variable "github_repo_id" {
  description = "Immutable numeric GitHub repository ID for OIDC claim pinning."
  type        = string
  default     = "1453269706"
}

variable "protected_bucket_name" {
  description = "GCS bucket accessible to the GitHub Actions WIF pipeline."
  type        = string
  default     = "available-only-to-github-pipeline"
}

variable "helloworld_object_name" {
  description = "Object key inside the protected bucket."
  type        = string
  default     = "helloworld.txt"
}

variable "helloworld_object_content" {
  description = "UTF-8 contents of the helloworld object."
  type        = string
  default     = "📙  😃  💁👌🎍"
}

variable "gitops_state_bucket_name" {
  description = "Dedicated GCS bucket storing remote Terraform state for the GitOps repo."
  type        = string
  default     = "gwx-sandbox-jingle-bells-tfstate"
}
