#reference: https://cloud.google.com/docs/terraform/best-practices/operations?hl=pt-br

terraform {
  backend "gcs" {
    bucket  = "terraform-state-bucket-sauter"
    prefix  = "artifact-registry" # reference: https://cloud.google.com/storage/docs/terraform-create-bucket-upload-object?hl=pt-br
  }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "sauter-university-472416"
  region  = "southamerica-east1"
}

resource "google_artifact_registry_repository" "artifactory_repository" {
  project       = "sauter-university-472416"
  location      = "southamerica-east1"
  repository_id = "docker-artifact-registry"
  format        = "DOCKER"
}