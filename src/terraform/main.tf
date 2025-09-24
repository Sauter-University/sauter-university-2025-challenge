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
  for_each = var.enable_apis ? toset(var.required_apis) : toset([])

  project = var.project_id
  service = each.key

  disable_dependent_services = var.disable_dependent_services
  disable_on_destroy         = var.disable_on_destroy
}

# Create cloud storage bucket
module "cloud_storage" {
  source = "./modules/cloud_storage"

  project_id        = var.project_id
  region            = var.region
  bucket_name       = var.storage_bucket_name
  storage_class     = var.storage_class
  force_destroy     = var.enable_bucket_force_destroy
  enable_versioning = var.enable_bucket_versioning

  labels = merge(var.common_labels, {
    environment = var.environment
    project     = var.project_name
    purpose     = "general"
    managed_by  = var.managed_by
  })

  depends_on = [
    google_project_service.apis
  ]
}

# Create monitoring infrastructure
module "monitoring" {
  source = "./modules/monitoring"

  project_id                = var.project_id
  notification_email        = var.budget_alert_email
  notification_display_name = var.notification_display_name

  depends_on = [
    google_project_service.apis
  ]
}

# Call the budget module
module "dev_budget" {
  source = "./modules/budget"

  project_id            = var.project_id
  billing_account_id    = var.billing_account_id
  budget_amount         = var.dev_budget_amount
  budget_display_name   = var.budget_display_name
  notification_channels = [module.monitoring.email_notification_channel_name]
  alert_thresholds      = var.budget_alert_thresholds
  enable_notifications  = var.enable_notifications

  depends_on = [
    google_project_service.apis,
    module.monitoring
  ]
}

# BigQuery Dataset for data warehouse
module "data_warehouse_dataset" {
  source = "./modules/bigquery"


  project_id                  = var.project_id
  dataset_id                  = var.bigquery_dataset_id
  dataset_friendly_name       = var.bigquery_dataset_friendly_name
  description                 = var.bigquery_dataset_description
  location                    = lookup(var.bigquery_location_mapping, var.region, upper(var.region))
  default_table_expiration_ms = null                            # No expiration for data warehouse tables
  delete_contents_on_destroy  = var.enable_bucket_force_destroy # Use same setting as buckets for consistency

  labels = merge(var.common_labels, {
    environment = var.environment
    project     = var.project_name
    purpose     = "data-warehouse"
    managed_by  = var.managed_by
  })

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
  description   = var.artifact_registry_description
  format        = var.artifact_registry_format

  labels = merge(var.common_labels, {
    environment = var.environment
    project     = var.project_name
    purpose     = "container-registry"
    managed_by  = var.managed_by
  })

  depends_on = [
    google_project_service.apis
  ]
}

# IAM module for all service accounts
module "iam" {
  source = "./modules/iam"

  project_id = var.project_id

  service_accounts = var.service_accounts_config
  
  depends_on = [
    google_project_service.apis
  ]
}

# Cloud Run service for hosting the Python API
module "cloud_run_api" {
  source = "./modules/cloud_run"

  project_id   = var.project_id
  region       = var.region
  service_name = var.cloud_run_service_name
  # Use a placeholder image until the actual image is built
  container_image       = var.cloud_run_default_image
  service_account_email = module.iam.service_account_emails["cloud_run_api"]

  # Resource configuration
  cpu_limit       = var.cloud_run_cpu_limit
  memory_limit    = var.cloud_run_memory_limit
  max_scale       = var.cloud_run_max_scale
  min_scale       = var.cloud_run_min_scale
  concurrency     = var.cloud_run_concurrency
  timeout_seconds = var.cloud_run_timeout_seconds

  # Security
  allow_unauthenticated = var.cloud_run_allow_unauthenticated
  deletion_protection   = var.cloud_run_deletion_protection

  # Environment variables (can be extended as needed)
  environment_variables = {
    PROJECT_ID = var.project_id
    REGION     = var.region
    ENV        = var.environment
  }

  # Labels
  labels = merge(var.common_labels, {
    environment = var.environment
    project     = var.project_name
    purpose     = "api-service"
    managed_by  = var.managed_by
  })

  depends_on = [
    google_project_service.apis,
    module.iam,
    module.docker_repository
  ]
}

# Workload Identity Federation for GitHub Actions
module "wif" {
  source = "./modules/wif"

  project_id = var.project_id
  # Pega o nome completo da SA 'ci_cd' que o módulo 'iam' acabou de criar
  service_account_name = module.iam.service_account_names["ci_cd"]
  # GitHub repository for Workload Identity Federation
  github_repository = var.github_repository

  depends_on = [
    module.iam
  ]
}

