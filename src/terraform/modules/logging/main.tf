# Cloud Logging sink to export logs to the terraform_logs bucket
resource "google_logging_project_sink" "terraform_logs_sink" {
  name                   = var.log_sink_name
  destination            = "storage.googleapis.com/${var.project_id}-${var.terraform_logs_bucket_name}"
  filter                 = var.log_filter
  unique_writer_identity = var.unique_writer_identity

  # Add description
  description = "Sink to export terraform-related logs to Cloud Storage bucket"
}

# IAM binding to allow the logging sink to write to the bucket
resource "google_storage_bucket_iam_member" "terraform_logs_sink_writer" {
  bucket = "${var.project_id}-${var.terraform_logs_bucket_name}"
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.terraform_logs_sink.writer_identity

  depends_on = [google_logging_project_sink.terraform_logs_sink]
}

# Additional logging configuration for structured logs
resource "google_logging_project_sink" "terraform_audit_logs_sink" {
  name                   = "${var.log_sink_name}-audit"
  destination            = "storage.googleapis.com/${var.project_id}-${var.terraform_logs_bucket_name}"
  filter                 = "protoPayload.methodName:\"terraform\" OR protoPayload.resourceName:\"terraform\" OR protoPayload.request.resource:\"terraform\""
  unique_writer_identity = var.unique_writer_identity

  description = "Sink to export terraform audit logs to Cloud Storage bucket"
}

# IAM binding for audit logs sink
resource "google_storage_bucket_iam_member" "terraform_audit_logs_sink_writer" {
  bucket = "${var.project_id}-${var.terraform_logs_bucket_name}"
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.terraform_audit_logs_sink.writer_identity

  depends_on = [google_logging_project_sink.terraform_audit_logs_sink]
}

# Log router for custom terraform logs
resource "google_logging_project_sink" "terraform_custom_logs_sink" {
  name                   = "${var.log_sink_name}-custom"
  destination            = "storage.googleapis.com/${var.project_id}-${var.terraform_logs_bucket_name}"
  filter                 = "jsonPayload.terraform_operation:*"
  unique_writer_identity = var.unique_writer_identity

  description = "Sink to export custom terraform operation logs to Cloud Storage bucket"
}

# IAM binding for custom logs sink
resource "google_storage_bucket_iam_member" "terraform_custom_logs_sink_writer" {
  bucket = "${var.project_id}-${var.terraform_logs_bucket_name}"
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.terraform_custom_logs_sink.writer_identity

  depends_on = [google_logging_project_sink.terraform_custom_logs_sink]
}
