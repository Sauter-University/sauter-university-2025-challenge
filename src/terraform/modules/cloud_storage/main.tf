# Terraform logs bucket
resource "google_storage_bucket" "terraform_logs" {
  name          = "${var.project_id}-${var.terraform_logs_bucket_name}"
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  versioning {
    enabled = var.enable_versioning
  }

  labels = {
    environment = "infrastructure"
    purpose     = "terraform-logs"
    managed_by  = "terraform"
  }
}

# API buckets using for_each
resource "google_storage_bucket" "api_buckets" {
  for_each = var.api_buckets

  name          = "${var.project_id}-${each.value.name}"
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  versioning {
    enabled = var.enable_versioning
  }

  labels = {
    environment = "api"
    purpose     = each.key
    data_type   = replace(lower(each.value.description), "/[^a-z0-9_-]/", "_")
    managed_by  = "terraform"
  }
}
