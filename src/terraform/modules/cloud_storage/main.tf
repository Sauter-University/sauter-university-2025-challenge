
resource "google_storage_bucket" "sauter_university_bucket" {
  name          = "bucket-sauter-university"
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  versioning {
    enabled = var.enable_versioning
  }

  labels = {
    environment = "production"
    purpose     = "general"
    managed_by  = "terraform"
  }
}
