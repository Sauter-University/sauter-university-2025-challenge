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
