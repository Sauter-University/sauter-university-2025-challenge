output "repository_id" {
  description = "The ID of the created Artifact Registry repository"
  value       = google_artifact_registry_repository.repository.repository_id
}

output "repository_name" {
  description = "The name of the created Artifact Registry repository"
  value       = google_artifact_registry_repository.repository.name
}

output "repository_url" {
  description = "The URL of the created Artifact Registry repository"
  value       = "https://${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repository.repository_id}"
}

output "create_time" {
  description = "The time when the repository was created"
  value       = google_artifact_registry_repository.repository.create_time
}

output "update_time" {
  description = "The time when the repository was last updated"
  value       = google_artifact_registry_repository.repository.update_time
}