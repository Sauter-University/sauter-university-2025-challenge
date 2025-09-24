# Terraform Variables Configuration
# This file contains custom values for the Sauter University infrastructure
# Copy this file and modify the values according to your requirements

# GCP Project Configuration
project_id = "sauter-university-472416"
region     = "us-central1"
zone       = "us-central1-a"

# Budget Configuration
dev_budget_amount  = 300
budget_alert_email = "sauter-university-472416@googlegroups.com"

# Terraform Backend Configuration
terraform_state_bucket = "sauter-university-472416-terraform-state"
terraform_state_prefix = "terraform/state"

# Temporarily enable force destroy for bucket migration
enable_bucket_force_destroy = true