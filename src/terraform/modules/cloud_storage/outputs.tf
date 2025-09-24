# Sauter University bucket outputs
output "bucket_name" {
  description = "Name of the Sauter University bucket"
  value       = google_storage_bucket.sauter_university_bucket.name
}

output "bucket_url" {
  description = "URL of the Sauter University bucket"
  value       = google_storage_bucket.sauter_university_bucket.url
}

output "bucket_self_link" {
  description = "Self link of the Sauter University bucket"
  value       = google_storage_bucket.sauter_university_bucket.self_link
}

# For backwards compatibility (these will be deprecated)
output "terraform_logs_bucket_name" {
  description = "Name of the bucket (backwards compatibility)"
  value       = google_storage_bucket.sauter_university_bucket.name
}

output "terraform_logs_bucket_url" {
  description = "URL of the bucket (backwards compatibility)"
  value       = google_storage_bucket.sauter_university_bucket.url
}

output "terraform_logs_bucket_self_link" {
  description = "Self link of the bucket (backwards compatibility)"
  value       = google_storage_bucket.sauter_university_bucket.self_link
}

output "api_bucket_names" {
  description = "Map of bucket names (backwards compatibility)"
  value = {
    main = google_storage_bucket.sauter_university_bucket.name
  }
}

output "api_bucket_urls" {
  description = "Map of bucket URLs (backwards compatibility)"
  value = {
    main = google_storage_bucket.sauter_university_bucket.url
  }
}

output "api_bucket_self_links" {
  description = "Map of bucket self links (backwards compatibility)"
  value = {
    main = google_storage_bucket.sauter_university_bucket.self_link
  }
}

output "all_bucket_names" {
  description = "List of all bucket names created by this module"
  value       = [google_storage_bucket.sauter_university_bucket.name]
}

output "bucket_summary" {
  description = "Summary of the created bucket"
  value = {
    main = {
      name = google_storage_bucket.sauter_university_bucket.name
      url  = google_storage_bucket.sauter_university_bucket.url
      type = "sauter-university"
    }
  }
}
