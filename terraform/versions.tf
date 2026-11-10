terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0, < 8.0.0"
    }
  }

  backend "gcs" {
    bucket = "gwx-sandbox-jingle-bells-tfstate"
    prefix = "gitops-pipeline"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
