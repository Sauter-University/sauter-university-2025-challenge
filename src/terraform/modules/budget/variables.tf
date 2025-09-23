variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "billing_account_id" {
  description = "The GCP billing account ID (optional - will use project's billing account if not specified)"
  type        = string
  default     = null
}

variable "budget_amount" {
  description = "The budget amount in BRL (Brazilian Reais)"
  type        = number
}

variable "budget_display_name" {
  description = "Display name for the budget"
  type        = string
}

variable "notification_channels" {
  description = "List of notification channel names for budget alerts"
  type        = list(string)
  default     = []
}

variable "alert_thresholds" {
  description = "Budget alert thresholds as percentages (0.5 = 50%)"
  type        = list(number)
  default     = [0.5, 0.75, 0.9, 1.0]
}

variable "currency_code" {
  description = "The currency code for the budget"
  type        = string
  default     = "BRL"
}

variable "enable_notifications" {
  description = "Whether to enable budget notifications"
  type        = bool
  default     = true
}
