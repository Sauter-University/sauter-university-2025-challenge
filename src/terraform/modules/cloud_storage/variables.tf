variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the buckets"
  type        = string
  default     = "us-central1"
}



variable "force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects"
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "The storage class of the buckets"
  type        = string
  default     = "STANDARD"
}

variable "enable_versioning" {
  description = "Enable versioning on the buckets"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Name of the storage bucket"
  type        = string
  default     = "bucket-sauter-university"
}

variable "labels" {
  description = "Labels to apply to the storage bucket"
  type        = map(string)
  default = {
    environment = "production"
    purpose     = "general"
    managed_by  = "terraform"
  }
}
