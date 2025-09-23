output "email_notification_channel_name" {
  description = "The name of the email notification channel"
  value       = var.enable_budget_alerts ? google_monitoring_notification_channel.email_budget[0].name : null
}

output "email_notification_channel_id" {
  description = "The ID of the email notification channel"
  value       = var.enable_budget_alerts ? google_monitoring_notification_channel.email_budget[0].id : null
}

output "additional_notification_channels" {
  description = "List of additional notification channel names"
  value       = [for channel in google_monitoring_notification_channel.additional : channel.name]
}

output "compute_alert_policy_name" {
  description = "The name of the compute high CPU alert policy"
  value       = var.enable_compute_alerts ? google_monitoring_alert_policy.compute_high_cpu[0].name : null
}

output "storage_alert_policy_name" {
  description = "The name of the storage usage alert policy"
  value       = var.enable_storage_alerts ? google_monitoring_alert_policy.storage_usage[0].name : null
}

output "custom_alert_policies" {
  description = "List of custom alert policy names"
  value       = [for policy in google_monitoring_alert_policy.custom : policy.name]
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main_dashboard.id}?project=${var.project_id}"
}

output "dashboard_id" {
  description = "The ID of the monitoring dashboard"
  value       = google_monitoring_dashboard.main_dashboard.id
}

output "notification_channels_summary" {
  description = "Summary of all notification channels"
  value = {
    email_channel = var.enable_budget_alerts ? {
      name  = google_monitoring_notification_channel.email_budget[0].name
      email = var.notification_email
    } : null
    additional_channels = [
      for i, channel in google_monitoring_notification_channel.additional : {
        name = channel.name
        type = channel.type
      }
    ]
  }
}