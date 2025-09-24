output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.name
}

output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.uri
}

output "service_id" {
  description = "The ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.id
}

output "service_location" {
  description = "The location of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.location
}

output "service_latest_ready_revision" {
  description = "The latest ready revision of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.latest_ready_revision
}

output "service_latest_created_revision" {
  description = "The latest created revision of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.latest_created_revision
}

output "service_conditions" {
  description = "The conditions of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.conditions
}

output "service_terminal_condition" {
  description = "The terminal condition of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_service.terminal_condition
}
