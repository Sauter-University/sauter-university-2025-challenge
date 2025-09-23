# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# IAM bindings for all service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for combination in flatten([
      for sa_key, sa_config in var.service_accounts : [
        for role in sa_config.roles : {
          key = "${sa_key}-${role}"
          service_account = sa_key
          role = role
        }
      ]
    ]) : combination.key => combination
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_account].email}"

  depends_on = [
    google_service_account.service_accounts
  ]
}
