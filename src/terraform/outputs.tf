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

# Data source to get project info for outputs
data "google_project" "project" {
  project_id = var.project_id
}
