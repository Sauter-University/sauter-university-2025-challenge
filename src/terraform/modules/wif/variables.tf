variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "service_account_name" {
  description = "The full name of the service account to bind to the WIF provider (e.g., projects/.../serviceAccounts/...)"
  type        = string
}

variable "github_repository" {
  description = "The GitHub repository in the format 'owner/repository_name'"
  type        = string
}

variable "pool_id" {
  description = "The ID for the Workload Identity Pool"
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "The ID for the Workload Identity Pool Provider"
  type        = string
  default     = "github-provider"
}