output "terraform_logs_sink_id" {
  description = "The ID of the terraform logs sink"
  value       = google_logging_project_sink.terraform_logs_sink.id
}

output "terraform_logs_sink_name" {
  description = "The name of the terraform logs sink"
  value       = google_logging_project_sink.terraform_logs_sink.name
}

output "terraform_logs_sink_writer_identity" {
  description = "The writer identity of the terraform logs sink"
  value       = google_logging_project_sink.terraform_logs_sink.writer_identity
}

output "terraform_audit_logs_sink_id" {
  description = "The ID of the terraform audit logs sink"
  value       = google_logging_project_sink.terraform_audit_logs_sink.id
}

output "terraform_audit_logs_sink_writer_identity" {
  description = "The writer identity of the terraform audit logs sink"
  value       = google_logging_project_sink.terraform_audit_logs_sink.writer_identity
}

output "terraform_custom_logs_sink_id" {
  description = "The ID of the terraform custom logs sink"
  value       = google_logging_project_sink.terraform_custom_logs_sink.id
}

output "terraform_custom_logs_sink_writer_identity" {
  description = "The writer identity of the terraform custom logs sink"
  value       = google_logging_project_sink.terraform_custom_logs_sink.writer_identity
}

output "all_sink_writer_identities" {
  description = "All writer identities for the logging sinks"
  value = [
    google_logging_project_sink.terraform_logs_sink.writer_identity,
    google_logging_project_sink.terraform_audit_logs_sink.writer_identity,
    google_logging_project_sink.terraform_custom_logs_sink.writer_identity
  ]
}
