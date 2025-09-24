# Cloud Run service for the Python API
resource "google_cloud_run_v2_service" "api_service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  # Allow deletion for development environment
  deletion_protection = var.deletion_protection
  
  labels = var.labels

  template {
    labels = var.labels
    
    # Service account for the Cloud Run service
    service_account = var.service_account_email

    # Scaling configuration
    scaling {
      max_instance_count = var.max_scale
      min_instance_count = var.min_scale
    }

    # Timeout configuration
    timeout = "${var.timeout_seconds}s"

    containers {
      image = var.container_image
      
      # Resource limits
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle = true
        startup_cpu_boost = false
      }

      # Port configuration
      ports {
        container_port = var.container_port
        name          = "http1"
      }

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Startup and liveness probes for better health checking
      startup_probe {
        http_get {
          path = "/"
          port = var.container_port
        }
        initial_delay_seconds = 10
        timeout_seconds      = 5
        period_seconds       = 10
        failure_threshold    = 3
      }

      liveness_probe {
        http_get {
          path = "/"
          port = var.container_port
        }
        initial_delay_seconds = 30
        timeout_seconds      = 5
        period_seconds       = 30
        failure_threshold    = 3
      }
    }

    # Container concurrency
    max_instance_request_concurrency = var.concurrency
  }

  # Traffic configuration
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      # Ignore changes to client and client_version as they are set by gcloud
      client,
      client_version,
    ]
  }
}

