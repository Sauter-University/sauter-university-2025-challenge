# Output the budget name for reference
output "budget_name" {
  description = "The name of the created budget"
  value       = google_billing_budget.dev_budget.name
}

output "budget_id" {
  description = "The ID of the created budget"
  value       = google_billing_budget.dev_budget.id
}

output "budget_display_name" {
  description = "The display name of the created budget"
  value       = google_billing_budget.dev_budget.display_name
}

output "budget_amount" {
  description = "The configured budget amount"
  value       = var.budget_amount
}

output "currency_code" {
  description = "The currency code used for the budget"
  value       = var.currency_code
}