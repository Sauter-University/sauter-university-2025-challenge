output "email_notification_channel_name" {
  description = "The name of the email notification channel"
  value       = google_monitoring_notification_channel.email_budget.name
}

output "email_notification_channel_id" {
  description = "The ID of the email notification channel"
  value       = google_monitoring_notification_channel.email_budget.id
}