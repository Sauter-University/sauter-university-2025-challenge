# Sauter University GCP Infrastructure

This Terraform configuration sets up the initial Google Cloud Platform (GCP) infrastructure for Sauter University, including project setup, billing alerts, and monitoring.

## 🏗️ Architecture Overview

The infrastructure consists of:
- **Main Configuration**: Core GCP project setup and API enablement
- **Budget Module**: Billing budgets and cost alerts
- **Monitoring Module**: Notification channels and alert policies
- **Cloud Storage Module**: Google Cloud Storage buckets for data management
- **BigQuery Module**: Data warehouse dataset for analytics and reporting
- **Artifact Registry Module**: Docker container registry for application images
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
    ├── bigquery/       # BigQuery data warehouse module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── artifact_registry/ # Docker container registry module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
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
| `bigquery_dataset_id` | BigQuery dataset ID | `sauter_challenge_dataset` | No |
| `artifact_registry_repository_id` | Artifact Registry repository ID | `sauter-university-docker-repo` | No |
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

# BigQuery Configuration
bigquery_dataset_id = "your_custom_dataset"

# Artifact Registry Configuration
artifact_registry_repository_id = "your-docker-repo"
```

## 📊 Enabled Google Cloud APIs

The configuration automatically enables these APIs:
- `artifactregistry.googleapis.com` - Artifact Registry for container images
- `bigquery.googleapis.com` - BigQuery data warehouse
- `billingbudgets.googleapis.com` - Billing budgets
- `cloudbilling.googleapis.com` - Cloud billing
- `cloudresourcemanager.googleapis.com` - Resource management
- `compute.googleapis.com` - Compute Engine
- `iam.googleapis.com` - Identity and Access Management
- `logging.googleapis.com` - Cloud Logging
- `monitoring.googleapis.com` - Cloud Monitoring
- `storage.googleapis.com` - Cloud Storage

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

## �️ BigQuery Data Warehouse

### Dataset Configuration

The infrastructure provisions a BigQuery dataset for data warehouse operations:

#### Dataset Details
- **Dataset ID**: `sauter_challenge_dataset` (configurable via `bigquery_dataset_id` variable)
- **Friendly Name**: "Sauter University Data Warehouse"
- **Location**: Automatically set based on region (`US` for `us-central1`, otherwise uppercase region)
- **Purpose**: Store processed university data for analytics and reporting

#### Features
- **No Table Expiration**: Tables persist indefinitely for data warehouse use cases
- **Flexible Access Control**: Configurable access permissions
- **Proper Labeling**: Environment, project, and purpose labels for organization
- **Force Destroy**: Follows same setting as storage buckets for consistency

#### Access Control
The dataset includes default access controls that can be customized in the module configuration.

#### Usage Examples
```bash
# Query the dataset using bq CLI
bq ls sauter_challenge_dataset

# Create a table in the dataset
bq mk -t sauter_challenge_dataset.university_data \
  student_id:STRING,name:STRING,enrollment_date:DATE

# Query data
bq query --use_legacy_sql=false \
  'SELECT * FROM `sauter-university-472416.sauter_challenge_dataset.university_data` LIMIT 10'
```

## 🐳 Artifact Registry (Docker Repository)

### Container Registry Configuration

The infrastructure provisions an Artifact Registry repository for storing Docker container images:

#### Repository Details
- **Repository ID**: `sauter-university-docker-repo` (configurable via `artifact_registry_repository_id` variable)
- **Format**: `DOCKER` - Specifically configured for Docker container images
- **Location**: Uses the same region as other resources (`us-central1`)
- **Purpose**: Store application container images for deployment

#### Repository URL
```
https://us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo
```

#### Features
- **Docker Format**: Optimized for Docker container storage
- **Regional Storage**: Located in the same region as other resources
- **Proper Labeling**: Environment, project, and purpose labels
- **IAM Integration**: Integrates with GCP IAM for access control

#### Usage Examples
```bash
# Configure Docker to use the registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag your image for the registry
docker tag my-app:latest \
  us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/my-app:latest

# Push image to the registry
docker push \
  us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/my-app:latest

# Pull image from the registry
docker pull \
  us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/my-app:latest

# List all images in the repository
gcloud artifacts docker images list us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo
```

## �🔧 Maintenance

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
| `bigquery_dataset` | BigQuery dataset information (ID, URL, creation time) |
| `artifact_registry_repository` | Artifact Registry repository information (ID, name, URL) |
| `infrastructure_summary` | Summary of all provisioned infrastructure |
| `storage_buckets_summary` | Summary of all Cloud Storage buckets |
| `enabled_apis` | List of all enabled Google Cloud APIs |

### Accessing Output Values
```bash
# View all outputs
terraform output

# View specific output
terraform output bigquery_dataset
terraform output artifact_registry_repository

# Get repository URL for Docker commands
terraform output -json artifact_registry_repository | jq -r '.repository_url'
```

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