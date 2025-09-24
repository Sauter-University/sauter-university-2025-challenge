variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

variable "notification_display_name" {
  description = "Display name for the notification channel"
  type        = string
  default     = "Budget Alert Notification Channel"
}
