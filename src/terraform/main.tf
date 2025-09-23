terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  user_project_override = true
  billing_project       = var.project_id
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy        = false
}

# Create cloud storage buckets
module "cloud_storage" {
  source = "./modules/cloud_storage"

  project_id                  = var.project_id
  region                     = var.region
  terraform_logs_bucket_name = "terraform-logs"
  force_destroy              = var.enable_bucket_force_destroy
  enable_versioning          = true

  depends_on = [
    google_project_service.apis
  ]
}

# Configure logging to terraform_logs bucket
# This module creates logging sinks to export logs to the GCS bucket
module "logging" {
  source = "./modules/logging"

  project_id                  = var.project_id
  terraform_logs_bucket_name = "terraform-logs"
  log_sink_name              = "terraform-logs-sink"
  unique_writer_identity     = true

  depends_on = [
    google_project_service.apis,
    module.cloud_storage,  # Bucket must exist first
    module.iam            # IAM permissions must be set first
  ]
}

# Create monitoring infrastructure
module "monitoring" {
  source = "./modules/monitoring"

  project_id                = var.project_id
  notification_email        = var.budget_alert_email
  notification_display_name = "Sauter University Budget Alerts"
  enable_budget_alerts      = true
  enable_compute_alerts     = false 
  enable_storage_alerts     = false

  depends_on = [
    google_project_service.apis
  ]
}

# Call the budget module
module "dev_budget" {
  source = "./modules/budget"

  project_id              = var.project_id
  billing_account_id      = var.billing_account_id
  budget_amount          = var.dev_budget_amount
  budget_display_name    = var.budget_display_name
  notification_channels  = module.monitoring.email_notification_channel_name != null ? [module.monitoring.email_notification_channel_name] : []
  alert_thresholds       = var.budget_alert_thresholds
  enable_notifications   = true

  depends_on = [
    google_project_service.apis,
    module.monitoring
  ]
}

# BigQuery Dataset for data warehouse
module "data_warehouse_dataset" {
  source = "./modules/bigquery"

  project_id                  = var.project_id
  dataset_id                 = var.bigquery_dataset_id
  dataset_friendly_name      = "Sauter University Data Warehouse"
  description                = "Data warehouse dataset for storing processed university data for analytics and reporting"
  location                   = var.region == "us-central1" ? "US" : upper(var.region)
  default_table_expiration_ms = null # No expiration for data warehouse tables
  delete_contents_on_destroy = var.enable_bucket_force_destroy # Use same setting as buckets for consistency

  labels = {
    environment = "development"
    project     = "sauter-university"
    purpose     = "data-warehouse"
    managed_by  = "terraform"
  }

  depends_on = [
    google_project_service.apis
  ]
}

# Artifact Registry Repository for Docker images
module "docker_repository" {
  source = "./modules/artifact_registry"

  project_id    = var.project_id
  repository_id = var.artifact_registry_repository_id
  location      = var.region
  description   = "Docker repository for storing Sauter University application container images"
  format        = "DOCKER"

  labels = {
    environment = "development"
    project     = "sauter-university"
    purpose     = "container-registry"
    managed_by  = "terraform"
  }

  depends_on = [
    google_project_service.apis
  ]
}

# IAM module for all service accounts
module "iam" {
  source = "./modules/iam"

  project_id = var.project_id
  
  service_accounts = {
    cloud_run_api = {
      account_id   = "cloud-run-api-sa"
      display_name = "Cloud Run API Service Account"
      description  = "Service account for Cloud Run API with minimum required permissions"
      roles = [
        "roles/bigquery.dataViewer",
        "roles/bigquery.jobUser",
        "roles/storage.objectViewer"
      ]
    }
    terraform = {
      account_id   = "terraform-sa"
      display_name = "Terraform Service Account"
      description  = "Service account for Terraform infrastructure management operations"
      roles = [
        "roles/compute.admin",
        "roles/storage.admin",
        "roles/bigquery.admin",
        "roles/artifactregistry.admin",
        "roles/iam.serviceAccountAdmin",
        "roles/iam.serviceAccountUser",
        "roles/logging.admin",
        "roles/monitoring.admin",
        "roles/resourcemanager.projectIamAdmin",
        "roles/serviceusage.serviceUsageAdmin"
      ]
    }
  }

  depends_on = [
    google_project_service.apis
  ]
}


