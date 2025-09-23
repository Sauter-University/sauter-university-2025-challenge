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
  default     = "resource.type=\"gce_instance\" OR resource.type=\"k8s_container\" OR protoPayload.serviceName=\"compute.googleapis.com\" OR protoPayload.serviceName=\"storage.googleapis.com\" OR labels.terraform=\"true\""
}

variable "unique_writer_identity" {
  description = "Whether to create a unique identity for the sink"
  type        = bool
  default     = true
}
