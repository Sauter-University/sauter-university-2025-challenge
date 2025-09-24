output "workload_identity_provider_name" {
  description = "The full name of the Workload Identity Provider for GitHub Actions."
  value       = google_iam_workload_identity_pool_provider.provider.name
}

output "workload_identity_pool_id" {
  description = "The ID of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.pool.workload_identity_pool_id
}