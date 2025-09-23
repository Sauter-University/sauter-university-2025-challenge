# Sauter University GCP Infrastructure

This Terraform configuration sets up the initial Google Cloud Platform (GCP) infrastructure for Sauter University, including project setup, billing alerts, and monitoring.

## 🏗️ Architecture Overview

The infrastructure consists of:
- **Main Configuration**: Core GCP project setup and API enablement
- **IAM Module**: Service accounts and role assignments with security best practices
- **Budget Module**: Billing budgets and cost alerts (using native GCP notifications)
- **Cloud Storage Module**: Google Cloud Storage buckets for data management
- **BigQuery Module**: Data warehouse dataset for analytics and reporting
- **Artifact Registry Module**: Docker container registry for application images
- **Cloud Run Module**: Serverless container platform for hosting Python API

## ☁️ Cloud Run Platform (Python API Hosting)

### Serverless Container Platform Configuration

The infrastructure provisions a Google Cloud Run service for hosting the Python FastAPI application in a fully managed, serverless environment.

#### Cloud Run Service Details
- **Service Name**: `sauter-reservoir-api` (configurable via `cloud_run_service_name` variable)
- **Platform**: Cloud Run v2 (latest generation)
- **Location**: Uses the same region as other resources (`us-central1`)
- **Purpose**: Host the Python FastAPI application for reservoir data management

#### Service URL
```
https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app
```

#### Key Features

##### 🔄 **Auto-scaling Configuration**
- **Minimum Instances**: 0 (scales to zero when no traffic)
- **Maximum Instances**: 10 (scales up based on demand)
- **Concurrency**: 80 concurrent requests per instance
- **CPU Idle**: Enabled for cost optimization

##### 💻 **Resource Allocation**
- **CPU**: 1000m (1 vCPU) with startup CPU boost disabled
- **Memory**: 512Mi RAM
- **Request Timeout**: 300 seconds (5 minutes)
- **Port**: 8080 (HTTP/1)

##### 🛡️ **Security & Access**
- **Service Account**: `cloud-run-api-sa@sauter-university-472416.iam.gserviceaccount.com`
- **Public Access**: Enabled (`allUsers` can invoke)
- **Deletion Protection**: Disabled for development environment
- **IAM Integration**: Uses dedicated service account with minimal permissions

##### 🔍 **Health Monitoring**
- **Startup Probe**: HTTP GET on port 8080, path "/"
  - Initial delay: 10 seconds
  - Timeout: 5 seconds
  - Period: 10 seconds
  - Failure threshold: 3 attempts

- **Liveness Probe**: HTTP GET on port 8080, path "/"
  - Initial delay: 30 seconds
  - Timeout: 5 seconds
  - Period: 30 seconds
  - Failure threshold: 3 attempts

##### 🌍 **Environment Variables**
Default environment variables configured:
```bash
PROJECT_ID=sauter-university-472416
REGION=us-central1
ENV=development
```

#### Container Image Configuration

The service is configured to use container images from the Artifact Registry:
```
us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:latest
```

#### Traffic Management
- **Traffic Allocation**: 100% to latest revision
- **Traffic Type**: `TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST`
- **Revision Management**: Automatic revision creation on updates

#### Usage Examples

##### Deploy New Container Version
```bash
# Build and push new container image
gcloud builds submit --tag us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:v2.0 .

# Update Cloud Run service with new image
gcloud run deploy sauter-reservoir-api \
  --image us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:v2.0 \
  --region us-central1 \
  --platform managed
```

##### Scale Configuration
```bash
# Update scaling limits
gcloud run services update sauter-reservoir-api \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 20 \
  --concurrency 100
```

##### Check Service Status
```bash
# Get service details
gcloud run services describe sauter-reservoir-api --region us-central1

# View service logs
gcloud logs read --filter="resource.type=cloud_run_revision AND resource.labels.service_name=sauter-reservoir-api" --limit=50

# Monitor traffic
gcloud run services list --filter="sauter-reservoir-api"
```

##### Test API Endpoints
```bash
# Test root endpoint
curl https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/

# Test API documentation
curl https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/docs

# Test with authentication (if needed)
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/api/reservoirs
```

#### Cost Optimization Features

##### 💰 **Pay-per-Use Pricing**
- **No charges** when service receives no requests
- **CPU allocation** charged only during request processing
- **Memory allocation** optimized for FastAPI applications
- **First 2 million requests/month** are free

##### ⚡ **Performance Optimization**
- **Cold start minimization** with proper health checks
- **CPU idle** feature reduces costs during low traffic
- **Automatic scaling** prevents over-provisioning
- **Regional deployment** reduces latency

#### Integration with Other Services

##### 📊 **BigQuery Integration**
The Cloud Run service can access BigQuery through the service account:
```python
# Example Python code for BigQuery access
from google.cloud import bigquery

client = bigquery.Client()
query = """
    SELECT * FROM `sauter-university-472416.sauter_challenge_dataset.reservoirs`
    LIMIT 100
"""
results = client.query(query)
```

##### 🗄️ **Cloud Storage Integration**
Access to Cloud Storage buckets for data files:
```python
# Example Python code for Cloud Storage access
from google.cloud import storage

client = storage.Client()
bucket = client.bucket('sauter-university-472416-api-raw-data')
blob = bucket.blob('reservoir_data.json')
data = blob.download_as_text()
```

#### Terraform Configuration Example

```hcl
module "cloud_run_api" {
  source = "./modules/cloud_run"

  project_id            = var.project_id
  region               = var.region
  service_name         = var.cloud_run_service_name
  container_image      = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository_id}/sauter-reservoir-api:${var.container_image_tag}"
  service_account_email = module.iam.service_account_emails["cloud_run_api"]
  
  # Resource configuration
  cpu_limit            = "1000m"
  memory_limit         = "512Mi"
  max_scale           = 10
  min_scale           = 0
  
  # Security and access
  allow_unauthenticated = true
  deletion_protection   = false
  
  # Environment variables
  environment_variables = {
    PROJECT_ID = var.project_id
    REGION     = var.region
    ENV        = "development"
  }
  
  # Labels for organization
  labels = {
    environment = "development"
    project     = "sauter-university"
    purpose     = "api-service"
    managed_by  = "terraform"
  }
}
```

#### Monitoring and Observability

##### 📈 **Built-in Metrics**
- Request count and latency
- Instance count and utilization
- Error rates and response codes
- Cold start frequency and duration

##### 🔍 **Cloud Logging Integration**
- Application logs automatically collected
- Request logs with correlation IDs
- Error tracking and alerting
- Performance monitoring

##### 🚨 **Native Monitoring Integration**
Cloud Run provides native integration with Google Cloud Operations for:
- Automatic metrics collection and dashboards
- Built-in error rate monitoring
- Latency and performance tracking
- Auto-scaling based on traffic patterns
- Resource utilization monitoring via Cloud Monitoring console

## 📁 Project Structure

```
src/terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── README.md           # This file
└── modules/
    ├── iam/            # IAM service accounts and roles module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── budget/         # Budget and billing alerts module
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
    └── cloud_run/      # Cloud Run serverless platform module
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
| `cloud_run_service_name` | Cloud Run service name | `sauter-reservoir-api` | No |
| `container_image_tag` | Container image tag | `latest` | No |
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
- `run.googleapis.com` - Cloud Run serverless platform
- `storage.googleapis.com` - Cloud Storage

## 🔐 Identity and Access Management (IAM)

### Service Accounts

The infrastructure creates and manages service accounts following the principle of least privilege. Each service account is granted only the minimum permissions required for its intended purpose.

#### 1. Cloud Run API Service Account
- **Account ID**: `cloud-run-api-sa`
- **Display Name**: Cloud Run API Service Account
- **Description**: Service account for Cloud Run API with minimum required permissions
- **Email**: `cloud-run-api-sa@sauter-university-472416.iam.gserviceaccount.com`

**Assigned IAM Roles**:
- `roles/bigquery.dataViewer` - Read access to BigQuery datasets and tables
- `roles/bigquery.jobUser` - Permission to run BigQuery jobs and queries
- `roles/storage.objectViewer` - Read access to Cloud Storage objects

**Use Case**: This service account is designed for the Cloud Run API application to access data resources safely with read-only permissions.

#### 2. Terraform Service Account
- **Account ID**: `terraform-sa`
- **Display Name**: Terraform Service Account
- **Description**: Service account for Terraform infrastructure management operations
- **Email**: `terraform-sa@sauter-university-472416.iam.gserviceaccount.com`

**Assigned IAM Roles**:
- `roles/compute.admin` - Full access to Compute Engine resources
- `roles/storage.admin` - Full access to Cloud Storage buckets and objects
- `roles/bigquery.admin` - Full access to BigQuery datasets, tables, and jobs
- `roles/artifactregistry.admin` - Full access to Artifact Registry repositories
- `roles/iam.serviceAccountAdmin` - Create and manage service accounts
- `roles/iam.serviceAccountUser` - Impersonate and use service accounts
- `roles/logging.admin` - Full access to Cloud Logging resources
- `roles/resourcemanager.projectIamAdmin` - Manage project-level IAM policies
- `roles/serviceusage.serviceUsageAdmin` - Enable and disable Google Cloud APIs

**Use Case**: This service account is designed for Terraform to manage the complete infrastructure lifecycle with administrative privileges.

### IAM Configuration

The IAM module uses a flexible configuration approach that allows easy addition of new service accounts:

```hcl
module "iam" {
  source = "./modules/iam"
  
  project_id = var.project_id
  
  service_accounts = {
    cloud_run_api = {
      account_id   = "cloud-run-api-sa"
      display_name = "Cloud Run API Service Account"
      description  = "Service account for Cloud Run API with minimum required permissions"
      roles = [
        "roles/bigquery.dataViewer",
        "roles/bigquery.jobUser",
        "roles/storage.objectViewer"
      ]
    }
    terraform = {
      account_id   = "terraform-sa"
      display_name = "Terraform Service Account"
      description  = "Service account for Terraform infrastructure management operations"
      roles = [
        "roles/compute.admin",
        "roles/storage.admin",
        "roles/bigquery.admin",
        "roles/artifactregistry.admin",
        "roles/iam.serviceAccountAdmin",
        "roles/iam.serviceAccountUser",
        "roles/logging.admin",
        "roles/resourcemanager.projectIamAdmin",
        "roles/serviceusage.serviceUsageAdmin"
      ]
    }
  }
}
```

### Security Best Practices

1. **Principle of Least Privilege**: Each service account has only the minimum permissions required
2. **Separation of Concerns**: Different service accounts for different purposes (API access vs infrastructure management)
3. **Role-Based Access Control**: Using predefined Google Cloud IAM roles rather than custom roles where possible
4. **Resource-Level Security**: Permissions granted at the appropriate resource level

### Service Account Outputs

The IAM module provides comprehensive outputs for integration with other infrastructure components:

```bash
# View all service account information
terraform output service_accounts_info

# Get specific service account email
terraform output -json service_account_emails | jq -r '.cloud_run_api'

# Get all service account emails
terraform output service_account_emails
```

### Adding New Service Accounts

To add a new service account, simply extend the `service_accounts` map in the main configuration:

```hcl
service_accounts = {
  # Existing service accounts...
  
  new_service = {
    account_id   = "new-service-sa"
    display_name = "New Service Account"
    description  = "Description of the new service account"
    roles = [
      "roles/specific.role1",
      "roles/specific.role2"
    ]
  }
}
```

### IAM Binding Management

The module automatically creates IAM bindings for all specified roles using a dynamic approach that:
- Creates unique combinations of service accounts and roles
- Manages dependencies properly
- Allows for easy role additions and removals
- Maintains consistent naming conventions

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

## 📈 Native GCP Monitoring

The infrastructure leverages Google Cloud's native monitoring capabilities:

- **Budget Alerts**: Managed through Cloud Billing console
- **Cloud Run Monitoring**: Automatic metrics via Cloud Operations
- **Resource Monitoring**: Built-in dashboards in Cloud Console
- **Performance Insights**: Native APM through Cloud Trace and Profiler

All monitoring is handled by Google Cloud Platform's native services, eliminating the need for custom alert policies and notification channels.

## 🗄️ Cloud Storage Configuration

### Created Buckets

The infrastructure automatically creates the following Google Cloud Storage buckets:

#### API Data Buckets
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
| `api_service_url` | Cloud Run service URL for the deployed API |
| `api_service_name` | Cloud Run service name |
| `api_service_location` | Cloud Run service location/region |
| `service_account_emails` | Map of all service account emails |
| `service_account_names` | Map of all service account names |
| `service_accounts_info` | Complete service accounts information |
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

# Get Cloud Run service information
terraform output api_service_url
terraform output api_service_name
terraform output api_service_location

# Get service account information
terraform output service_account_emails
terraform output service_accounts_info

# Get specific service account email for use in configurations
terraform output -json service_account_emails | jq -r '.cloud_run_api'
terraform output -json service_account_emails | jq -r '.terraform'
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

Minimum required roles for deploying this infrastructure:
- `roles/billing.admin` - For budget creation and billing account management
- `roles/serviceusage.serviceUsageAdmin` - For API management and enablement
- `roles/resourcemanager.projectIamAdmin` - For project-level IAM changes
- `roles/iam.serviceAccountAdmin` - For creating and managing service accounts
- `roles/storage.admin` - For creating and managing Cloud Storage buckets
- `roles/bigquery.admin` - For creating and managing BigQuery datasets
- `roles/artifactregistry.admin` - For creating and managing Artifact Registry repositories
- `roles/run.admin` - For creating and managing Cloud Run services

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