variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region where the Cloud Run service will be deployed"
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "sauter-reservoir-api"
}

variable "container_image" {
  description = "The container image URL for the Cloud Run service"
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account for Cloud Run"
  type        = string
}

variable "container_port" {
  description = "The port that the container listens on"
  type        = number
  default     = 8080
}

variable "cpu_limit" {
  description = "CPU limit for the Cloud Run service"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "max_scale" {
  description = "Maximum number of container instances"
  type        = number
  default     = 10
}

variable "min_scale" {
  description = "Minimum number of container instances"
  type        = number
  default     = 0
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "concurrency" {
  description = "Maximum number of concurrent requests per container instance"
  type        = number
  default     = 80
}

variable "allow_unauthenticated" {
  description = "Whether to allow unauthenticated access to the service"
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Environment variables for the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to attach to the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the Cloud Run service"
  type        = bool
  default     = false
}
