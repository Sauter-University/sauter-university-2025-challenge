variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "terraform_logs_bucket_name" {
  description = "Name of the bucket to store terraform logs"
  type        = string
}

variable "log_sink_name" {
  description = "Name of the Cloud Logging sink"
  type        = string
  default     = "terraform-logs-sink"
}

variable "log_filter" {
  description = "Filter for Cloud Logging sink to capture terraform-related logs"
  type        = string
  default     = "protoPayload.serviceName=\"storage.googleapis.com\" OR protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\" OR protoPayload.serviceName=\"iam.googleapis.com\" OR protoPayload.serviceName=\"logging.googleapis.com\" OR protoPayload.serviceName=\"bigquery.googleapis.com\" OR protoPayload.serviceName=\"artifactregistry.googleapis.com\""
}

variable "unique_writer_identity" {
  description = "Whether to create a unique identity for the sink"
  type        = bool
  default     = true
}
