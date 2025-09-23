# Terraform logs bucket outputs
output "terraform_logs_bucket_name" {
  description = "Name of the terraform logs bucket"
  value       = google_storage_bucket.terraform_logs.name
}

output "terraform_logs_bucket_url" {
  description = "URL of the terraform logs bucket"
  value       = google_storage_bucket.terraform_logs.url
}

output "terraform_logs_bucket_self_link" {
  description = "Self link of the terraform logs bucket"
  value       = google_storage_bucket.terraform_logs.self_link
}

# API buckets outputs
output "api_bucket_names" {
  description = "Map of API bucket names"
  value = {
    for k, bucket in google_storage_bucket.api_buckets : k => bucket.name
  }
}

output "api_bucket_urls" {
  description = "Map of API bucket URLs"
  value = {
    for k, bucket in google_storage_bucket.api_buckets : k => bucket.url
  }
}

output "api_bucket_self_links" {
  description = "Map of API bucket self links"
  value = {
    for k, bucket in google_storage_bucket.api_buckets : k => bucket.self_link
  }
}

# All buckets combined
output "all_bucket_names" {
  description = "List of all bucket names created by this module"
  value = concat(
    [google_storage_bucket.terraform_logs.name],
    [for bucket in google_storage_bucket.api_buckets : bucket.name]
  )
}

output "bucket_summary" {
  description = "Summary of all created buckets"
  value = {
    terraform_logs = {
      name = google_storage_bucket.terraform_logs.name
      url  = google_storage_bucket.terraform_logs.url
      type = "terraform-logs"
    }
    api_buckets = {
      for k, bucket in google_storage_bucket.api_buckets : k => {
        name = bucket.name
        url  = bucket.url
        type = "api-${k}"
      }
    }
  }
}
