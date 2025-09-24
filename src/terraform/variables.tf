variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "sauter-university-472416"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "dev_budget_amount" {
  description = "The budget amount for development environment in BRL (Brazilian Reais)"
  type        = number
  default     = 300
}

variable "budget_alert_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = "sauter-university-472416@googlegroups.com"
}

variable "budget_display_name" {
  description = "Display name for the budget"
  type        = string
  default     = "Sauter University Dev Budget"
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [0.5, 0.75, 0.9, 1.0]
}

variable "billing_account_id" {
  description = "The GCP billing account ID for budget creation"
  type        = string
  default     = "01E2EF-4F5B53-1C7A01"
}

variable "enable_bucket_force_destroy" {
  description = "Enable force destroy for storage buckets (useful for development)"
  type        = bool
  default     = false
}

variable "bigquery_dataset_id" {
  description = "The BigQuery dataset ID for the data warehouse"
  type        = string
  default     = "sauter_challenge_dataset"
}

variable "artifact_registry_repository_id" {
  description = "The Artifact Registry repository ID for Docker images"
  type        = string
  default     = "sauter-university-docker-repo"
}

variable "cloud_run_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "sauter-api-hub"
}

variable "container_image_tag" {
  description = "The tag for the container image"
  type        = string
  default     = "latest"
}

# API Services Configuration
variable "required_apis" {
  description = "List of APIs to enable for the project"
  type        = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com"
  ]
}

# Environment and Labeling Configuration
variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name for labeling resources"
  type        = string
  default     = "sauter-university"
}

variable "managed_by" {
  description = "Tool used to manage the infrastructure"
  type        = string
  default     = "terraform"
}

# Monitoring Configuration
variable "notification_display_name" {
  description = "Display name for monitoring notifications"
  type        = string
  default     = "Sauter University Budget Alerts"
}

# BigQuery Configuration
variable "bigquery_dataset_friendly_name" {
  description = "Friendly name for the BigQuery dataset"
  type        = string
  default     = "Sauter University Data Warehouse"
}

variable "bigquery_dataset_description" {
  description = "Description for the BigQuery dataset"
  type        = string
  default     = "Data warehouse dataset for storing processed university data for analytics and reporting"
}

variable "bigquery_location_mapping" {
  description = "Mapping of regions to BigQuery locations"
  type        = map(string)
  default = {
    "us-central1"     = "US"
    "us-east1"        = "US"
    "us-west1"        = "US"
    "europe-west1"    = "EU"
    "asia-southeast1" = "asia-southeast1"
  }
}

# Artifact Registry Configuration
variable "artifact_registry_description" {
  description = "Description for the Artifact Registry repository"
  type        = string
  default     = "Docker repository for storing Sauter University application container images"
}

variable "artifact_registry_format" {
  description = "Format for the Artifact Registry repository"
  type        = string
  default     = "DOCKER"
}

# Service Accounts Configuration
variable "service_accounts_config" {
  description = "Configuration for service accounts"
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {
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
        "roles/serviceusage.serviceUsageAdmin",
        "roles/run.admin"
      ]
    }
    ci_cd = {
      account_id   = "ci-cd-github-sa"
      display_name = "CI/CD GitHub Actions Service Account"
      description  = "Service account for the CI/CD pipeline on GitHub Actions"
      roles = [
        "roles/artifactregistry.writer",
        "roles/run.admin",
        "roles/iam.serviceAccountUser"
      ]
    }
  }
}

# Cloud Run Configuration
variable "cloud_run_default_image" {
  description = "Default container image for Cloud Run service"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "cloud_run_cpu_limit" {
  description = "CPU limit for Cloud Run service"
  type        = string
  default     = "1000m"
}

variable "cloud_run_memory_limit" {
  description = "Memory limit for Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "cloud_run_max_scale" {
  description = "Maximum number of instances for Cloud Run service"
  type        = number
  default     = 10
}

variable "cloud_run_min_scale" {
  description = "Minimum number of instances for Cloud Run service"
  type        = number
  default     = 0
}

variable "cloud_run_concurrency" {
  description = "Maximum number of concurrent requests per instance"
  type        = number
  default     = 80
}

variable "cloud_run_timeout_seconds" {
  description = "Request timeout in seconds for Cloud Run service"
  type        = number
  default     = 300
}

variable "cloud_run_allow_unauthenticated" {
  description = "Allow unauthenticated access to Cloud Run service"
  type        = bool
  default     = true
}

variable "cloud_run_deletion_protection" {
  description = "Enable deletion protection for Cloud Run service"
  type        = bool
  default     = false
}

# GitHub Repository Configuration
variable "github_repository" {
  description = "GitHub repository for Workload Identity Federation"
  type        = string
  default     = "Sauter-University/sauter-university-2025-challenge"
}

# Enable/Disable Configuration
variable "enable_apis" {
  description = "Whether to enable required APIs"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Whether to enable budget notifications"
  type        = bool
  default     = true
}

variable "disable_dependent_services" {
  description = "Whether to disable dependent services when disabling APIs"
  type        = bool
  default     = false
}

variable "disable_on_destroy" {
  description = "Whether to disable APIs on terraform destroy"
  type        = bool
  default     = false
}

# Storage Configuration
variable "storage_bucket_name" {
  description = "Name for the main storage bucket"
  type        = string
  default     = "bucket-sauter-university"
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"
}

variable "enable_bucket_versioning" {
  description = "Enable versioning on storage buckets"
  type        = bool
  default     = true
}

# Common Labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Terraform Backend Configuration
variable "terraform_state_bucket" {
  description = "GCS bucket name for storing Terraform state"
  type        = string
  default     = "sauter-university-472416-terraform-state"
}

variable "terraform_state_prefix" {
  description = "Prefix for Terraform state files in GCS bucket"
  type        = string
  default     = "terraform/state"
}
