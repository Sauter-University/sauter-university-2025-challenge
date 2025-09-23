# Data source to get project billing info
data "google_project" "project" {
  project_id = var.project_id
}

# Create the budget using the project's billing account directly
resource "google_billing_budget" "dev_budget" {
  billing_account = var.billing_account_id != null ? var.billing_account_id : data.google_project.project.billing_account
  display_name    = var.budget_display_name

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = tostring(var.budget_amount)
    }
  }

  # Create threshold rules for each alert threshold
  dynamic "threshold_rules" {
    for_each = var.alert_thresholds
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  # Configure notifications if enabled and channels are provided
  dynamic "all_updates_rule" {
    for_each = var.enable_notifications && length(var.notification_channels) > 0 ? [1] : []
    content {
      monitoring_notification_channels = var.notification_channels
      
      disable_default_iam_recipients = false
      
      schema_version = "1.0"
    }
  }
}


