# Primary email notification channel for budget alerts
resource "google_monitoring_notification_channel" "email_budget" {
  display_name = var.notification_display_name
  type         = "email"

  labels = {
    email_address = var.notification_email
  }

  user_labels = {
    purpose     = "budget-alerts"
    environment = "dev"
    team        = "sauter-university"
  }
}