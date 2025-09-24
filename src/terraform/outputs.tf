# Terraform Backend Outputs
output "terraform_state_bucket_name" {
  description = "The name of the Terraform state bucket"
  value       = module.terraform_state_bucket.bucket_name
}

output "terraform_state_bucket_url" {
  description = "The URL of the Terraform state bucket"
  value       = module.terraform_state_bucket.bucket_url
}

output "terraform_backend_config" {
  description = "Backend configuration values for Terraform"
  value = {
    bucket = var.terraform_state_bucket
    prefix = var.terraform_state_prefix
  }
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.project.number
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

output "budget_amount" {
  description = "The configured budget amount in USD"
  value       = var.dev_budget_amount
}

output "budget_name" {
  description = "The name of the created budget"
  value       = module.dev_budget.budget_name
}

output "budget_id" {
  description = "The ID of the created budget"
  value       = module.dev_budget.budget_id
}

output "budget_alert_email" {
  description = "The email address configured for budget alerts"
  value       = var.budget_alert_email
}

output "monitoring_notification_channel" {
  description = "The monitoring notification channel information"
  value = {
    email_channel_name = module.monitoring.email_notification_channel_name
    email_channel_id   = module.monitoring.email_notification_channel_id
  }
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.apis : api.service]
}

# Cloud Storage outputs
output "sauter_university_bucket" {
  description = "Information about the Sauter University bucket"
  value = {
    name      = module.cloud_storage.bucket_name
    url       = module.cloud_storage.bucket_url
    self_link = module.cloud_storage.bucket_self_link
  }
}

# Backwards compatibility outputs
output "terraform_logs_bucket" {
  description = "Information about the bucket (backwards compatibility)"
  value = {
    name      = module.cloud_storage.terraform_logs_bucket_name
    url       = module.cloud_storage.terraform_logs_bucket_url
    self_link = module.cloud_storage.terraform_logs_bucket_self_link
  }
}

output "api_buckets" {
  description = "Information about the bucket (backwards compatibility)"
  value = {
    names      = module.cloud_storage.api_bucket_names
    urls       = module.cloud_storage.api_bucket_urls
    self_links = module.cloud_storage.api_bucket_self_links
  }
}

output "storage_buckets_summary" {
  description = "Summary of all created storage buckets"
  value       = module.cloud_storage.bucket_summary
}

# BigQuery outputs
output "bigquery_dataset" {
  description = "Information about the BigQuery data warehouse dataset"
  value = {
    dataset_id         = module.data_warehouse_dataset.dataset_id
    dataset_url        = module.data_warehouse_dataset.dataset_url
    creation_time      = module.data_warehouse_dataset.creation_time
    last_modified_time = module.data_warehouse_dataset.last_modified_time
  }
}

# Artifact Registry outputs
output "artifact_registry_repository" {
  description = "Information about the Artifact Registry Docker repository"
  value = {
    repository_id   = module.docker_repository.repository_id
    repository_name = module.docker_repository.repository_name
    repository_url  = module.docker_repository.repository_url
    create_time     = module.docker_repository.create_time
    update_time     = module.docker_repository.update_time
  }
}

# Service Account outputs
output "cloud_run_api_service_account" {
  description = "Information about the Cloud Run API service account"
  value       = module.iam.service_account_info
}

output "cloud_run_api_service_account_email" {
  description = "Email of the Cloud Run API service account"
  value       = module.iam.service_account_email
}

# Terraform Service Account outputs
output "terraform_service_account" {
  description = "Information about the Terraform service account"
  value       = module.iam.service_accounts_info["terraform"]
}

output "terraform_service_account_email" {
  description = "Email of the Terraform service account"
  value       = module.iam.service_account_emails["terraform"]
}

# All service accounts output
output "all_service_accounts" {
  description = "Information about all service accounts"
  value       = module.iam.service_accounts_info
}

# Cloud Run outputs
output "api_service_url" {
  description = "The URL of the deployed API service"
  value       = module.cloud_run_api.service_url
}

output "api_service_name" {
  description = "The name of the API service"
  value       = module.cloud_run_api.service_name
}

output "api_service_location" {
  description = "The location of the API service"
  value       = module.cloud_run_api.service_location
}

# Infrastructure summary
output "infrastructure_summary" {
  description = "Summary of all provisioned infrastructure"
  value = {
    project_id       = var.project_id
    region           = var.region
    bigquery_dataset = module.data_warehouse_dataset.dataset_id
    docker_registry  = module.docker_repository.repository_url
    storage_buckets  = 1
    enabled_apis     = length([for api in google_project_service.apis : api.service])
    service_account  = module.iam.service_account_email
    terraform_sa     = module.iam.service_account_emails["terraform"]
    api_service_url  = module.cloud_run_api.service_url
  }
}

output "cicd_service_account_email" {
  description = "The email of the Service Account for the CI/CD pipeline."
  value       = module.iam.service_account_emails["ci_cd"]
}

output "workload_identity_provider_name" {
  description = "The full name of the Workload Identity Provider for GitHub Actions."
  value       = module.wif.workload_identity_provider_name
}
