# Primary email notification channel for budget alerts
resource "google_monitoring_notification_channel" "email_budget" {
  count        = var.enable_budget_alerts ? 1 : 0
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

# Additional notification channels
resource "google_monitoring_notification_channel" "additional" {
  count        = length(var.additional_notification_channels)
  display_name = var.additional_notification_channels[count.index].display_name
  type         = var.additional_notification_channels[count.index].type

  labels      = var.additional_notification_channels[count.index].labels
  user_labels = var.additional_notification_channels[count.index].user_labels
}

# Compute instance high CPU alert policy
# resource "google_monitoring_alert_policy" "compute_high_cpu" {
#   count        = var.enable_compute_alerts ? 1 : 0
#   display_name = "High CPU Usage Alert"
#   combiner     = "OR"

#   conditions {
#     display_name = "VM Instance - High CPU"

#     condition_threshold {
#       filter          = "resource.type=\"gce_instance\""
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0.8
#       duration        = "300s"

#       aggregations {
#         alignment_period   = "60s"
#         per_series_aligner = "ALIGN_MEAN"
#       }
#     }
#   }

#   notification_channels = var.enable_budget_alerts ? [google_monitoring_notification_channel.email_budget[0].name] : []

#   alert_strategy {
#     auto_close = "1800s"
#   }
# }

# Storage usage alert policy
resource "google_monitoring_alert_policy" "storage_usage" {
  count        = var.enable_storage_alerts ? 1 : 0
  display_name = "High Storage Usage Alert"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Storage - High Usage"

    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\""
      comparison      = "COMPARISON_GT"
      threshold_value = 50000000000 # 50GB in bytes
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.enable_budget_alerts ? [google_monitoring_notification_channel.email_budget[0].name] : []

  alert_strategy {
    auto_close = "1800s"
  }
}

# Custom alert policies
resource "google_monitoring_alert_policy" "custom" {
  count        = length(var.alert_policies)
  display_name = var.alert_policies[count.index].display_name
  combiner     = var.alert_policies[count.index].combiner

  dynamic "conditions" {
    for_each = var.alert_policies[count.index].conditions
    content {
      display_name = conditions.value.display_name

      condition_threshold {
        filter          = conditions.value.filter
        comparison      = conditions.value.comparison
        threshold_value = conditions.value.threshold_value
        duration        = conditions.value.threshold_duration

        aggregations {
          alignment_period   = "60s"
          per_series_aligner = "ALIGN_MEAN"
        }
      }
    }
  }

  notification_channels = var.enable_budget_alerts ? [google_monitoring_notification_channel.email_budget[0].name] : []

  alert_strategy {
    auto_close = "1800s"
  }
}

# Monitoring dashboard for budget and resource usage
resource "google_monitoring_dashboard" "main_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Sauter University - Resource Monitoring"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Project Resource Count"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/count\" resource.type=\"gce_instance\""
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Compute Instance CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 12
          height = 4
          yPos   = 4
          widget = {
            title = "Storage Bucket Object Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"storage.googleapis.com/storage/object_count\" resource.type=\"gcs_bucket\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}