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
  value       = module.monitoring.notification_channels_summary
}

output "monitoring_dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.apis : api.service]
}

# Cloud Storage outputs
output "terraform_logs_bucket" {
  description = "Information about the terraform logs bucket"
  value = {
    name      = module.cloud_storage.terraform_logs_bucket_name
    url       = module.cloud_storage.terraform_logs_bucket_url
    self_link = module.cloud_storage.terraform_logs_bucket_self_link
  }
}

output "api_buckets" {
  description = "Information about the API buckets"
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

# Logging outputs - temporarily commented out due to permission issues
# output "terraform_logs_sink" {
#   description = "Information about the terraform logs sink"
#   value = {
#     id               = module.logging.terraform_logs_sink_id
#     name            = module.logging.terraform_logs_sink_name
#     writer_identity = module.logging.terraform_logs_sink_writer_identity
#   }
# }

# output "logging_sinks_summary" {
#   description = "Summary of all logging sinks"
#   value = {
#     terraform_logs_sink_id     = module.logging.terraform_logs_sink_id
#     audit_logs_sink_id         = module.logging.terraform_audit_logs_sink_id
#     custom_logs_sink_id        = module.logging.terraform_custom_logs_sink_id
#     all_writer_identities      = module.logging.all_sink_writer_identities
#   }
# }

# Data source to get project info for outputs
data "google_project" "project" {
  project_id = var.project_id
}

# BigQuery outputs
output "bigquery_dataset" {
  description = "Information about the BigQuery data warehouse dataset"
  value = {
    dataset_id           = module.data_warehouse_dataset.dataset_id
    dataset_url          = module.data_warehouse_dataset.dataset_url
    creation_time        = module.data_warehouse_dataset.creation_time
    last_modified_time   = module.data_warehouse_dataset.last_modified_time
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

# Infrastructure summary
output "infrastructure_summary" {
  description = "Summary of all provisioned infrastructure"
  value = {
    project_id          = var.project_id
    region              = var.region
    bigquery_dataset    = module.data_warehouse_dataset.dataset_id
    docker_registry     = module.docker_repository.repository_url
    storage_buckets     = length(module.cloud_storage.api_bucket_names)
    enabled_apis        = length([for api in google_project_service.apis : api.service])
  }
}
