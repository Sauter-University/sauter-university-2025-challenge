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
  disable_on_destroy         = false
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

  project_id            = var.project_id
  billing_account_id    = var.billing_account_id
  budget_amount         = var.dev_budget_amount
  budget_display_name   = var.budget_display_name
  notification_channels = module.monitoring.email_notification_channel_name != null ? [module.monitoring.email_notification_channel_name] : []
  alert_thresholds      = var.budget_alert_thresholds
  enable_notifications  = true

  depends_on = [
    google_project_service.apis,
    module.monitoring
  ]
}

# Create cloud storage buckets
module "cloud_storage" {
  source = "./modules/cloud_storage"

  project_id                 = var.project_id
  region                     = var.region
  terraform_logs_bucket_name = "terraform-logs"
  force_destroy              = var.enable_bucket_force_destroy
  enable_versioning          = true

  depends_on = [
    google_project_service.apis
  ]
}

# Configure logging to terraform_logs bucket
# Temporarily commented out due to permission issues
# module "logging" {
#   source = "./modules/logging"
#
#   project_id                  = var.project_id
#   terraform_logs_bucket_name = "terraform-logs"
#   log_sink_name              = "terraform-logs-sink"
#   unique_writer_identity     = true
#
#   depends_on = [
#     google_project_service.apis,
#     module.cloud_storage
#   ]
# }
