#reference: https://cloud.google.com/docs/terraform/best-practices/operations?hl=pt-br

terraform {
  # backend "gcs" {
  #   bucket  = "terraform-state-bucket-sauter"
  #   prefix  = "artifact-registry" 
  # }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "sauter-university-472416"
  region  = "us-central1"
}

resource "google_artifact_registry_repository" "artifactory_repository" {
  project       = "sauter-university-472416"
  location      = "us-central1"
  repository_id = "docker-artifact-registry"
  format        = "DOCKER"
}