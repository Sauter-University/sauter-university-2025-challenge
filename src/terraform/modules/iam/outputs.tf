output "service_account_emails" {
  description = "Map of service account emails"
  value = {
    for key, sa in google_service_account.service_accounts : key => sa.email
  }
}

output "service_account_names" {
  description = "Map of service account names"
  value = {
    for key, sa in google_service_account.service_accounts : key => sa.name
  }
}

output "service_account_ids" {
  description = "Map of service account IDs"
  value = {
    for key, sa in google_service_account.service_accounts : key => sa.account_id
  }
}

output "service_account_unique_ids" {
  description = "Map of service account unique IDs"
  value = {
    for key, sa in google_service_account.service_accounts : key => sa.unique_id
  }
}

output "service_accounts_info" {
  description = "Complete service accounts information"
  value = {
    for key, sa in google_service_account.service_accounts : key => {
      email      = sa.email
      name       = sa.name
      account_id = sa.account_id
      unique_id  = sa.unique_id
    }
  }
}

# Backward compatibility outputs for Cloud Run API service account
output "service_account_email" {
  description = "Email of the Cloud Run API service account (backward compatibility)"
  value       = try(google_service_account.service_accounts["cloud_run_api"].email, null)
}

output "service_account_info" {
  description = "Complete Cloud Run API service account information (backward compatibility)"
  value = try({
    email      = google_service_account.service_accounts["cloud_run_api"].email
    name       = google_service_account.service_accounts["cloud_run_api"].name
    account_id = google_service_account.service_accounts["cloud_run_api"].account_id
    unique_id  = google_service_account.service_accounts["cloud_run_api"].unique_id
  }, null)
}
