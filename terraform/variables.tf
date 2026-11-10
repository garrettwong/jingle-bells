variable "project_id" {
  description = "GCP Project ID."
  type        = string
  default     = "gwx-sandbox"
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "target_bucket" {
  description = "Protected GCS bucket readable only by the GitHub WIF pipeline."
  type        = string
  default     = "available-only-to-github-pipeline"
}

variable "target_object" {
  description = "Object name inside the protected GCS bucket."
  type        = string
  default     = "helloworld.txt"
}

variable "expected_content" {
  description = "Expected UTF-8 string stored in helloworld.txt."
  type        = string
  default     = "📙  😃  💁👌🎍"
}
