# Sauter University GCP Infrastructure

This Terraform configuration sets up the initial Google Cloud Platform (GCP) infrastructure for Sauter University, including project setup, billing alerts, and monitoring.

## 🏗️ Architecture Overview

The infrastructure consists of:
- **Main Configuration**: Core GCP project setup and API enablement
- **Budget Module**: Billing budgets and cost alerts
- **Monitoring Module**: Notification channels and alert policies
- **Cloud Storage Module**: Google Cloud Storage buckets for data management
- **Logging Module**: Cloud Logging configuration (currently disabled due to permissions)

## 📁 Project Structure

```
src/terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── README.md           # This file
└── modules/
    ├── budget/         # Budget and billing alerts module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/     # Monitoring and notifications module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloud_storage/  # Google Cloud Storage buckets module
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md   # Detailed bucket documentation
    └── logging/        # Cloud Logging configuration (disabled)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🚀 Quick Start

### Prerequisites

1. **Terraform**: Install Terraform >= 1.0
   ```bash
   # Check version
   terraform version
   ```

2. **Google Cloud SDK**: Install and configure gcloud CLI
   ```bash
   # Install gcloud (if not already installed)
   curl https://sdk.cloud.google.com | bash
   
   # Initialize and authenticate
   gcloud init
   gcloud auth application-default login
   ```

3. **GCP Project**: Ensure you have a GCP project with billing enabled

### Deployment Steps

1. **Clone and Navigate**
   ```bash
   cd src/terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review Configuration**
   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

5. **Verify Deployment**
   ```bash
   terraform show
   ```

## ⚙️ Configuration

### Required Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_id` | GCP Project ID | `sauter-university-472416` | No |
| `region` | GCP Region | `us-central1` | No |
| `zone` | GCP Zone | `us-central1-a` | No |
| `budget_alert_email` | Email for budget alerts | `sauter-university-472416@googlegroups.com` | No |
| `dev_budget_amount` | Budget amount in BRL | `300` | No |

### Variable Customization

Create a `terraform.tfvars` file to customize variables:

```hcl
# terraform.tfvars
project_id          = "your-project-id"
region              = "us-west1"
zone                = "us-west1-a"
budget_alert_email  = "your-email@domain.com"
dev_budget_amount   = 500
```

## 📊 Enabled Google Cloud APIs

The configuration automatically enables these APIs:
- `billingbudgets.googleapis.com` - Billing budgets
- `cloudbilling.googleapis.com` - Cloud billing
- `cloudresourcemanager.googleapis.com` - Resource management
- `compute.googleapis.com` - Compute Engine
- `iam.googleapis.com` - Identity and Access Management
- `monitoring.googleapis.com` - Cloud Monitoring

## 💰 Budget & Alerts

### Budget Configuration
- **Default Budget**: R$ 300 for development environment
- **Currency**: BRL (Brazilian Real)
- **Scope**: Entire project

### Alert Thresholds
Budget alerts are triggered at:
- 50% of budget (R$ 150)
- 90% of budget (R$ 270)
- 100% of budget (R$ 300)

### Notification Channels
- Email notifications to specified address
- Configurable additional channels (Slack, PagerDuty, etc.)

## 📈 Monitoring & Alerts

### Available Alert Policies
The monitoring module supports:
- **Budget Alerts**: ✅ Enabled by default

### Enabling Additional Alerts
```hcl
module "monitoring" {
  # ... other configuration
  enable_compute_alerts = true
  enable_storage_alerts = true
}
```

## 🗄️ Cloud Storage Configuration

### Created Buckets

The infrastructure automatically creates the following Google Cloud Storage buckets:

#### 1. Terraform Logs Bucket
- **Name**: `{project_id}-terraform-logs`
- **Purpose**: Store terraform operation logs and infrastructure audit trails
- **URL**: `gs://{project_id}-terraform-logs`

#### 2. API Data Buckets (using for_each)
- **Raw Data**: `{project_id}-api-raw-data` - Stores raw, unprocessed API data
- **Treated Data**: `{project_id}-api-treated-data` - Stores processed and cleaned API data  
- **ML Data**: `{project_id}-api-ml-data` - Stores ML training data, models, and ML-related artifacts

### Storage Configuration
- **Location**: `us-central1` (configurable via `region` variable)
- **Storage Class**: `STANDARD`
- **Versioning**: Enabled for data protection
- **Labels**: Applied for proper organization and cost tracking

### Usage Examples
```bash
# List all buckets
gsutil ls

# Upload to raw data bucket
gsutil cp data.json gs://sauter-university-472416-api-raw-data/

# Copy between buckets (raw → treated)
gsutil cp gs://sauter-university-472416-api-raw-data/data.json \
         gs://sauter-university-472416-api-treated-data/processed_data.json
```

### Detailed Documentation
For comprehensive bucket configuration details, see: [`modules/cloud_storage/README.md`](modules/cloud_storage/README.md)

## 🔧 Maintenance

### Updating Infrastructure
```

## 🔧 Maintenance
```

## � Email Testing System

### Simple Test Email Alerts

The infrastructure includes a test email system to verify that Google Group notifications are working properly before relying on budget alerts. This is especially important since budget alerts may take time to trigger naturally.

### Test Alert Configuration

Two test alert policies are created when `enable_test_email_alerts = true`:

1. **🚨 SIMPLE Test Email - Delete After Testing**
   - Triggers immediately using an absence condition
   - Tests basic email delivery to the Google Group
   - Purpose: Verify email notifications work

2. **🧪 Test Email - Budget Alert Group Verification**
   - Monitors compute instance CPU usage > 0.1%
   - Triggers when any VM shows activity
   - Purpose: Test realistic monitoring scenarios

### How to Test Email Delivery

1. **Enable test alerts** in `terraform.tfvars`:
   ```hcl
   enable_test_email_alerts     = true
   enable_immediate_test_email  = true
   ```

2. **Apply configuration**:
   ```bash
   terraform apply -auto-approve
   ```

3. **Check alert status** in Google Cloud Console:
   - Navigate to Monitoring > Alerting
   - Look for active alerts with "Test" in the name
   - Verify alerts are firing (status: "Open")

4. **Verify email delivery**:
   - Check the Google Group email: `sauter-university-472416@googlegroups.com`
   - Look for alert notification emails from GCP Monitoring
   - Emails should arrive within 5-15 minutes

### Triggering Test Alerts

To trigger the CPU-based test alert, create a small VM instance:
```bash
gcloud compute instances create test-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud
```

### Cleaning Up Test Resources

After confirming email delivery works:

1. **Disable test alerts**:
   ```hcl
   enable_test_email_alerts     = false
   enable_immediate_test_email  = false
   ```

2. **Remove test VM**:
   ```bash
   gcloud compute instances delete test-vm --zone=us-central1-a
   ```

3. **Apply changes**:
   ```bash
   terraform apply -auto-approve
   ```

### Why Email Testing Matters

- **Budget alerts** may take days/weeks to trigger naturally
- **Google Groups** require proper configuration to receive GCP notifications
- **Early verification** ensures you'll receive critical budget notifications
- **Peace of mind** knowing the alert system works before reaching spending thresholds

## �🔧 Maintenance

### Updating Infrastructure
```bash
# Check for configuration drift
terraform plan

# Apply changes
terraform apply

# View current state
terraform show
```

### Destroying Infrastructure
```bash
# Destroy all resources (use with caution!)
terraform destroy
```

### State Operations
```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show google_project_service.apis

# Import existing resource
terraform import google_project_service.apis project-id/service-name
```

## 📝 Outputs

After successful deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `project_id` | The GCP project ID |
| `project_number` | The GCP project number |
| `region` | The configured GCP region |
| `zone` | The configured GCP zone |
| `budget_name` | The created budget name |
| `notification_channels` | List of notification channel IDs |

## 🔍 Troubleshooting

### Common Issues

1. **API Not Enabled**
   ```
   Error: googleapi: Error 403: [API_NAME] API has not been used in project [PROJECT_ID]
   ```
   **Solution**: Wait for APIs to be fully enabled or manually enable in GCP Console

2. **Billing Account Issues**
   ```
   Error: Failed to get billing account
   ```
   **Solution**: Ensure project has billing account linked and you have billing permissions

3. **Permission Denied**
   ```
   Error: googleapi: Error 403: Permission denied
   ```
   **Solution**: Verify IAM permissions for the service account or user

### Required IAM Permissions

Minimum required roles:
- `roles/billing.admin` - For budget creation
- `roles/monitoring.admin` - For alert policies
- `roles/serviceusage.serviceUsageAdmin` - For API management
- `roles/resourcemanager.projectIamAdmin` - For project-level changes

## 📚 Additional Resources

- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Billing Budgets API](https://cloud.google.com/billing/docs/how-to/budgets)
- [GCP Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test locally
3. Run `terraform plan` to verify changes
4. Submit pull request with detailed description
5. Ensure all checks pass before merging


**Note**: This infrastructure is designed for the Sauter University 2025 Challenge. Modify configurations according to your specific requirements and security policies.