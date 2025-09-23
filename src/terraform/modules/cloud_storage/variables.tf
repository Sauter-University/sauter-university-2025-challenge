variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the buckets"
  type        = string
  default     = "us-central1"
}

variable "terraform_logs_bucket_name" {
  description = "Name for the terraform logs bucket"
  type        = string
  default     = "terraform-logs"
}

variable "api_buckets" {
  description = "Map of API bucket names and their configurations"
  type = map(object({
    name        = string
    description = string
  }))
  default = {
    raw = {
      name        = "api-raw-data"
      description = "Bucket for raw API data"
    }
    treated = {
      name        = "api-treated-data"
      description = "Bucket for processed/treated API data"
    }
    ml = {
      name        = "api-ml-data"
      description = "Bucket for ML training and model data"
    }
  }
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
