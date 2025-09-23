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

variable "enable_budget_alerts" {
  description = "Whether to enable budget alert notifications"
  type        = bool
  default     = true
}

variable "enable_compute_alerts" {
  description = "Whether to enable compute resource alerts"
  type        = bool
  default     = false
}

variable "enable_storage_alerts" {
  description = "Whether to enable storage alerts"
  type        = bool
  default     = false
}

variable "additional_notification_channels" {
  description = "Additional notification channels (Slack, PagerDuty, etc.)"
  type = list(object({
    type         = string
    display_name = string
    labels       = map(string)
    user_labels  = map(string)
  }))
  default = []
}

variable "alert_policies" {
  description = "Custom alert policies to create"
  type = list(object({
    display_name = string
    combiner     = string
    conditions = list(object({
      display_name = string
      filter       = string
      comparison   = string
      threshold_duration = string
      threshold_value = number
    }))
  }))
  default = []
}

variable "enable_test_alerts" {
  description = "Whether to enable test alert for email notification testing"
  type        = bool
  default     = false
}

variable "enable_test_email_alerts" {
  description = "Whether to enable test email alerts that trigger when compute instances are running"
  type        = bool
  default     = false
}

variable "enable_immediate_test_email" {
  description = "Whether to enable immediate test email alert (triggers right away for testing)"
  type        = bool
  default     = false
}