output "dataset_id" {
  description = "The ID of the created BigQuery dataset"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "dataset_url" {
  description = "The URL of the created BigQuery dataset"
  value       = google_bigquery_dataset.dataset.self_link
}

output "dataset_etag" {
  description = "A hash of the resource"
  value       = google_bigquery_dataset.dataset.etag
}

output "creation_time" {
  description = "The time when this dataset was created, in milliseconds since the epoch"
  value       = google_bigquery_dataset.dataset.creation_time
}

output "last_modified_time" {
  description = "The date when this dataset or any of its tables was last modified, in milliseconds since the epoch"
  value       = google_bigquery_dataset.dataset.last_modified_time
}