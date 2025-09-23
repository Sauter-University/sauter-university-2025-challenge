# Terraform Variables Configuration
# This file contains custom values for the Sauter University infrastructure
# Copy this file and modify the values according to your requirements

# GCP Project Configuration
project_id = "sauter-university-472416"
region     = "us-central1"
zone       = "us-central1-a"

# Budget Configuration
dev_budget_amount   = 300
budget_alert_email  = "sauter-university-472416@googlegroups.com"

# Test Email Configuration - Enable to test Google Group email delivery
enable_test_email_alerts    = true   # Enable test alerts when compute instances are running
enable_immediate_test_email = true   # Enable immediate test alert (triggers right away)