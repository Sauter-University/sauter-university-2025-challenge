# Test Email Alert Policy for Billing Budget Group Verification
# This creates a simple alert using basic GCP metrics to test email notifications

# Simple test alert that triggers on any compute activity
resource "google_monitoring_alert_policy" "test_email_verification" {
  count        = var.enable_test_email_alerts ? 1 : 0
  display_name = "🧪 Test Email - Budget Alert Group Verification"
  combiner     = "OR"
  enabled      = true
  
  documentation {
    content = "**EMAIL TEST ALERT** - Testing email delivery to: ${var.notification_email}. This alert verifies that billing budget notifications will be delivered correctly to the Google Group."
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Test - Any Compute Instance Activity"
    
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.001  # Very low threshold to trigger easily
      duration        = "60s"
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_budget_alerts ? [google_monitoring_notification_channel.email_budget[0].name] : []
  
  alert_strategy {
    auto_close = "3600s"  # Auto-close after 1 hour
  }

  user_labels = {
    purpose     = "email-testing"
    temporary   = "true"
    environment = "dev"
  }
}

# Alternative simpler test using a condition that should always exist
resource "google_monitoring_alert_policy" "simple_test_email" {
  count        = var.enable_immediate_test_email ? 1 : 0
  display_name = "🚨 SIMPLE Test Email - Delete After Testing"
  combiner     = "OR"
  enabled      = true
  
  documentation {
    content = "**SIMPLE TEST** - Testing email to: ${var.notification_email}. This is a basic test to verify email delivery works for budget alerts."
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Test Condition - Always True"
    
    condition_absent {
      filter   = "metric.type=\"compute.googleapis.com/firewall/dropped_packets_count\" resource.type=\"gce_instance\""
      duration = "120s"  # Minimum 2 minutes required for absence conditions
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.enable_budget_alerts ? [google_monitoring_notification_channel.email_budget[0].name] : []
  
  alert_strategy {
    auto_close = "1800s"  # Auto-close after 30 minutes
  }

  user_labels = {
    purpose   = "immediate-test"
    temporary = "true"
    delete_me = "after-testing"
  }
}