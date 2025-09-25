# Sauter University GCP Infrastructure

This Terraform configuration sets up the complete Google Cloud Platform (GCP) infrastructure for the Sauter University Reservoir Data Management System, a comprehensive solution for downloading, processing, and querying reservoir data from Brazil's National System Operator (ONS).

**✨ Following 100% Terraform Best Practices with complete variable-driven configuration!**

## 🏗️ Architecture Overview

The infrastructure consists of:
- **Main Configuration**: Core GCP project setup and API enablement
- **IAM Module**: Service accounts and role assignments with security best practices
- **Budget Module**: Billing budgets and cost alerts
- **Monitoring Module**: Notification channels and alert policies
- **Cloud Storage Module**: Single unified bucket (`bucket-sauter-university`) for all data management
- **BigQuery Module**: Data warehouse dataset (`sauter_challenge_dataset`) for analytics and reporting
- **Artifact Registry Module**: Docker container registry for application images
- **Cloud Run Module**: Serverless FastAPI application for reservoir data management
- **Workload Identity Federation Module**: Secure CI/CD integration with GitHub Actions

## 🎯 System Purpose

The **Sauter University Reservoir Data Management System** provides:

### 🌊 Core Functionality
- **Data Ingestion**: Automated download of reservoir data from Brazil's ONS (Operador Nacional do Sistema Elétrico)
- **Data Processing**: Clean, transform, and validate reservoir volume data
- **RESTful API**: FastAPI application providing endpoints for:
  - `/api/v1/ingest` - Trigger data ingestion for specific date ranges
  - `/api/v1/basin-volumes` - Query reservoir volume data with pagination
  - `/docs` - Interactive API documentation
  - Health checks and monitoring endpoints

### 🏗️ Infrastructure Design Philosophy

This infrastructure follows a **unified, cloud-native approach**:
- **Simplified Management**: Single unified bucket for all data types - easier permissions, monitoring, and cost tracking
- **Organized Structure**: Data organization through logical folder hierarchy rather than separate buckets
- **Serverless Architecture**: Cloud Run for auto-scaling, pay-per-use API hosting
- **Secure CI/CD**: Workload Identity Federation for keyless GitHub Actions authentication
- **Cost Efficiency**: Reduced complexity and optimized resource utilization
- **Data Warehouse Integration**: BigQuery for analytics and reporting on reservoir data

### 📋 Quick Reference Commands

```bash
# List container images in Artifact Registry
gcloud artifacts docker images list us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo

# Access API documentation
curl https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/docs

# Test API health
curl https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/

# Trigger data ingestion
curl -X POST https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app/api/v1/ingest \
  -H "Content-Type: application/json" \
  -d '{"start_date": "2024-01-01", "end_date": "2024-01-31"}'
```

## 🗃️ Remote State Backend Configuration

### Google Cloud Storage Backend

This Terraform configuration uses Google Cloud Storage as a remote backend to store the Terraform state file securely and enable team collaboration.

#### Backend Configuration Details
- **Backend Type**: Google Cloud Storage (GCS)
- **State Bucket**: `sauter-university-472416-terraform-state`
- **State Prefix**: `terraform/state`
- **Versioning**: Enabled for state file versioning and recovery
- **Force Destroy**: Disabled for state bucket protection

#### Setting Up the Remote Backend

1. **First-time Setup**: For initial deployment, the state bucket will be created by Terraform itself:
   ```bash
   # Initialize Terraform (first time without backend)
   terraform init
   
   # Apply to create the state bucket
   terraform apply -target=module.terraform_state_bucket
   ```

2. **Migrate to Remote Backend**: After the bucket is created, reinitialize with the backend:
   ```bash
   # Reinitialize with remote backend
   terraform init
   
   # Confirm migration when prompted
   ```

3. **Alternative Backend Configuration**: You can also use the backend configuration file:
   ```bash
   # Initialize with backend configuration file
   terraform init -backend-config=backend.tf
   ```

#### Backend Security & Best Practices
- **Bucket Versioning**: Enabled to maintain state file history
- **No Force Destroy**: State bucket cannot be accidentally deleted
- **Organized Prefix**: State files are organized under `terraform/state/` prefix
- **Team Collaboration**: Multiple team members can work with the same state

#### Backend Configuration Variables
```hcl
# In terraform.tfvars
terraform_state_bucket = "sauter-university-472416-terraform-state"
terraform_state_prefix = "terraform/state"
```

## ☁️ Cloud Run Platform (Reservoir Data API Hosting)

### Serverless FastAPI Application Configuration

The infrastructure provisions a Google Cloud Run service hosting the **Sauter Reservoir Data API** - a FastAPI application that manages reservoir data from Brazil's ONS (Operador Nacional do Sistema Elétrico).

#### Cloud Run Service Details
- **Service Name**: `sauter-api-hub` (configurable via `cloud_run_service_name` variable)
- **Platform**: Cloud Run v2 (latest generation)
- **Location**: Uses the same region as other resources (`us-central1`)
- **Purpose**: Host the FastAPI application for reservoir data ingestion, processing, and querying

#### API Information
- **Service URL**: `https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app`
- **API Title**: "Sauter Reservoir Data API"
- **Version**: "1.0.0"
- **Documentation**: Available at `/docs` endpoint with interactive Swagger UI

#### Available API Endpoints
```bash
# Root endpoint (health check)
GET /                           # Welcome message and API status

# Data ingestion
POST /api/v1/ingest            # Trigger data ingestion for date ranges

# Data querying  
GET /api/v1/basin-volumes      # Query reservoir volume data with pagination

# API documentation
GET /docs                      # Interactive Swagger UI documentation
GET /redoc                     # ReDoc API documentation
GET /openapi.json              # OpenAPI specification
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
- **Public Access**: Enabled (`allUsers` can invoke) - suitable for API endpoints
- **Deletion Protection**: Configurable per environment (disabled for development)
- **IAM Integration**: Uses dedicated service account with minimal required permissions:
  - `roles/bigquery.dataViewer` - Read access to reservoir datasets
  - `roles/bigquery.jobUser` - Execute queries for data retrieval
  - `roles/storage.objectViewer` - Read access to processed data in Cloud Storage

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
Default environment variables configured for the FastAPI application:
```bash
PROJECT_ID=sauter-university-472416    # GCP Project ID for service integration
REGION=us-central1                     # Deployment region
ENV=development                        # Environment identifier
GCS_BUCKET_NAME=bucket-sauter-university  # Bucket for data storage (when configured)
```

#### Container Image Configuration

The service uses container images from the Artifact Registry:
```bash
# Default placeholder image (until actual application is deployed)
gcr.io/cloudrun/hello

# Target container image location for FastAPI application
us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:latest
```

#### FastAPI Application Structure
```python
# Main application components
app = FastAPI(
    title="Sauter Reservoir Data API",
    description="An API to download and query reservoir data from Brazil's National System Operator (ONS).",
    version="1.0.0"
)

# Available routers and endpoints
- Basin Volume Router (/api/v1)
  - POST /ingest - Data ingestion from ONS
  - GET /basin-volumes - Query reservoir data
- Health Check (/) - System status
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
Access to the unified Cloud Storage bucket for all data files:
```python
# Example Python code for Cloud Storage access
from google.cloud import storage

client = storage.Client()
bucket = client.bucket('bucket-sauter-university')

# Access different types of data with organized paths
# Raw data
blob = bucket.blob('raw-data/reservoir_data.json')
raw_data = blob.download_as_text()

# Processed data
blob = bucket.blob('processed-data/cleaned_reservoir_data.json')
processed_data = blob.download_as_text()

# ML models
blob = bucket.blob('ml-models/reservoir_model.pkl')
model_data = blob.download_as_bytes()

# Logs
blob = bucket.blob('logs/application.log')
log_data = blob.download_as_text()
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

##### 🚨 **Alerting Integration**
Cloud Run metrics integrate with the monitoring module for:
- High error rate alerts
- Latency threshold alerts
- Instance scaling alerts
- Resource utilization monitoring

## 🔧 Maintenanceule**: Billing budgets and cost alerts
- **Monitoring Module**: Notification channels and alert policies
- **Cloud Storage Module**: Single unified Google Cloud Storage bucket for all data management
- **BigQuery Module**: Data warehouse dataset for analytics and reporting
- **Artifact Registry Module**: Docker container registry for application images
- **Cloud Run Module**: Serverless container platform for hosting Python API
- **Logging Module**: Cloud Logging configuration with log sinks

## 📁 Project Structure

```
src/terraform/
├── main.tf                    # Main Terraform configuration - 100% variable-driven
├── variables.tf               # Input variables (30+ comprehensive variables)
├── outputs.tf                 # Output values for all infrastructure components
├── backend.tf                 # Remote state backend configuration
├── terraform.tfvars.example   # Example configuration file
├── TERRAFORM_BEST_PRACTICES.md # Implementation guide
├── README.md                  # This comprehensive documentation
└── modules/
    ├── iam/                   # IAM service accounts and roles module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── budget/                # Budget and billing alerts module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── monitoring/            # Monitoring and notifications module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloud_storage/         # Google Cloud Storage unified bucket module
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md          # Detailed bucket documentation
    ├── bigquery/              # BigQuery data warehouse module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── artifact_registry/     # Docker container registry module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── cloud_run/             # Cloud Run FastAPI application module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── wif/                   # Workload Identity Federation (CI/CD) module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security_policies/     # Security policies module (reserved for future use)
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

2. **Configure Variables** (NEW - Best Practice!)
   ```bash
   # Copy the example configuration
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit with your specific values
   nano terraform.tfvars
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review Configuration**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

6. **Verify Deployment**
   ```bash
   terraform show
   ```

## ⚙️ Configuration - 100% Variable-Driven! 🎯

### 🌟 **New Best Practices Implementation**

This configuration now follows **100% Terraform best practices** with:
- ✅ **Zero hardcoded values** in main files
- ✅ **Complete variable coverage** for all resources  
- ✅ **Environment-specific configurations**
- ✅ **Consistent labeling** across all resources
- ✅ **Feature toggles** for optional components

### Core Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `project_id` | GCP Project ID | `sauter-university-472416` | string |
| `region` | GCP Region | `us-central1` | string |
| `zone` | GCP Zone | `us-central1-a` | string |
| `environment` | Environment (development/staging/production) | `development` | string |
| `project_name` | Project name for labeling | `sauter-university` | string |

### Budget & Billing Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `budget_alert_email` | Email for budget alerts | `sauter-university-472416@googlegroups.com` | string |
| `dev_budget_amount` | Budget amount in BRL | `300` | number |
| `budget_display_name` | Budget display name | `Sauter University Dev Budget` | string |
| `budget_alert_thresholds` | Alert thresholds | `[0.5, 0.75, 0.9, 1.0]` | list(number) |
| `billing_account_id` | Billing account ID | `01E2EF-4F5B53-1C7A01` | string |

### Cloud Run Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `cloud_run_service_name` | Service name | `sauter-api-hub` | string |
| `cloud_run_default_image` | Default container image | `gcr.io/cloudrun/hello` | string |
| `cloud_run_cpu_limit` | CPU limit | `1000m` | string |
| `cloud_run_memory_limit` | Memory limit | `512Mi` | string |
| `cloud_run_max_scale` | Maximum instances | `10` | number |
| `cloud_run_min_scale` | Minimum instances | `0` | number |
| `cloud_run_concurrency` | Concurrent requests per instance | `80` | number |
| `cloud_run_timeout_seconds` | Request timeout | `300` | number |

### Storage Configuration Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `storage_bucket_name` | Main bucket name | `bucket-sauter-university` | string |
| `storage_class` | Storage class | `STANDARD` | string |
| `enable_bucket_force_destroy` | Allow deletion with objects | `false` | bool |
| `enable_bucket_versioning` | Enable versioning | `true` | bool |

### Feature Toggle Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `enable_apis` | Enable required APIs | `true` | bool |
| `enable_notifications` | Enable budget notifications | `true` | bool |
| `disable_dependent_services` | Disable dependent services on destroy | `false` | bool |

### Advanced Configuration Variables

| Variable | Description | Type |
|----------|-------------|------|
| `required_apis` | List of APIs to enable | list(string) |
| `service_accounts_config` | Complete service account configuration | map(object) |
| `common_labels` | Common labels for all resources | map(string) |
| `bigquery_location_mapping` | Region to BigQuery location mapping | map(string) |

### Variable Customization

**Method 1: Using terraform.tfvars (Recommended)**
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Method 2: Environment Variables**
```bash
export TF_VAR_project_id="your-project-id"
export TF_VAR_environment="production"
export TF_VAR_budget_alert_email="your-email@domain.com"
```

**Method 3: Command Line**
```bash
terraform apply -var="project_id=your-project-id" -var="environment=production"
```

### Example terraform.tfvars Configuration

```hcl
# Core Configuration
project_id   = "your-project-id"
region       = "us-central1"
environment  = "development"
project_name = "sauter-university"

# Budget Configuration
budget_alert_email  = "your-email@domain.com"
dev_budget_amount   = 300
billing_account_id  = "your-billing-account-id"

# Cloud Run Configuration
cloud_run_service_name     = "sauter-api-hub"
cloud_run_cpu_limit       = "1000m"
cloud_run_memory_limit    = "512Mi"
cloud_run_max_scale       = 10

# Storage Configuration
storage_bucket_name         = "bucket-sauter-university"
enable_bucket_force_destroy = true  # Use true for dev, false for prod

# Feature Toggles
enable_apis          = true
enable_notifications = true

# Common Labels (applied to all resources)
common_labels = {
  team        = "data-engineering"
  cost-center = "engineering"
  owner       = "sauter-university"
}
```

### Multi-Environment Configuration

**Development Environment (terraform.tfvars)**
```hcl
environment                 = "development"
enable_bucket_force_destroy = true
cloud_run_deletion_protection = false
dev_budget_amount          = 300
```

**Production Environment (production.tfvars)**
```hcl
environment                 = "production" 
enable_bucket_force_destroy = false
cloud_run_deletion_protection = true
dev_budget_amount          = 1000
cloud_run_min_scale        = 1
cloud_run_max_scale        = 50
```

**Deployment with Environment-Specific Config**
```bash
# Development
terraform apply

# Production
terraform apply -var-file="production.tfvars"
```

## 📊 Enabled Google Cloud APIs - Now Configurable! 

The configuration automatically enables APIs via the `required_apis` variable (fully customizable):

**Default API List:**
- `artifactregistry.googleapis.com` - Artifact Registry for container images
- `bigquery.googleapis.com` - BigQuery data warehouse  
- `billingbudgets.googleapis.com` - Billing budgets
- `cloudbilling.googleapis.com` - Cloud billing
- `cloudresourcemanager.googleapis.com` - Resource management
- `compute.googleapis.com` - Compute Engine
- `iam.googleapis.com` - Identity and Access Management
- `logging.googleapis.com` - Cloud Logging
- `monitoring.googleapis.com` - Cloud Monitoring
- `run.googleapis.com` - Cloud Run serverless platform
- `storage.googleapis.com` - Cloud Storage

**Customizing APIs (terraform.tfvars):**
```hcl
# Add additional APIs as needed
required_apis = [
  "artifactregistry.googleapis.com",
  "bigquery.googleapis.com", 
  "billingbudgets.googleapis.com",
  "cloudbilling.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "compute.googleapis.com",
  "iam.googleapis.com",
  "logging.googleapis.com", 
  "monitoring.googleapis.com",
  "run.googleapis.com",
  "storage.googleapis.com",
  # Add your custom APIs here
  "pubsub.googleapis.com",
  "cloudfunctions.googleapis.com"
]
```

**Feature Toggles:**
```hcl
enable_apis = true  # Set to false to skip API enablement
disable_dependent_services = false
disable_on_destroy = false
```

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
- `roles/storage.objectViewer` - Read access to the unified Cloud Storage bucket (`bucket-sauter-university`)

**Use Case**: This service account is designed for the Cloud Run API application to access data resources safely with read-only permissions across the unified storage bucket.

#### 2. Terraform Service Account
- **Account ID**: `terraform-sa`
- **Display Name**: Terraform Service Account
- **Description**: Service account for Terraform infrastructure management operations
- **Email**: `terraform-sa@sauter-university-472416.iam.gserviceaccount.com`

**Assigned IAM Roles**:
- `roles/compute.admin` - Full access to Compute Engine resources
- `roles/storage.admin` - Full access to the unified Cloud Storage bucket and all objects
- `roles/bigquery.admin` - Full access to BigQuery datasets, tables, and jobs
- `roles/artifactregistry.admin` - Full access to Artifact Registry repositories
- `roles/iam.serviceAccountAdmin` - Create and manage service accounts
- `roles/iam.serviceAccountUser` - Impersonate and use service accounts
- `roles/logging.admin` - Full access to Cloud Logging resources
- `roles/monitoring.admin` - Full access to Cloud Monitoring resources
- `roles/resourcemanager.projectIamAdmin` - Manage project-level IAM policies
- `roles/serviceusage.serviceUsageAdmin` - Enable and disable Google Cloud APIs

**Use Case**: This service account is designed for Terraform to manage the complete infrastructure lifecycle with administrative privileges, including full control over the unified storage bucket.

### IAM Configuration - Now Fully Variable-Driven! 🔐

The IAM module uses a **completely configurable approach** via the `service_accounts_config` variable:

**Default Configuration:**
```hcl
# Now configured via variables.tf - 100% customizable!
module "iam" {
  source = "./modules/iam"
  
  project_id = var.project_id
  service_accounts = var.service_accounts_config  # ← All from variables!
}
```

**Customizing Service Accounts (terraform.tfvars):**
```hcl
service_accounts_config = {
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
      "roles/monitoring.admin", 
      "roles/resourcemanager.projectIamAdmin",
      "roles/serviceusage.serviceUsageAdmin",
      "roles/run.admin"
    ]
  }
  ci_cd = {
    account_id   = "ci-cd-github-sa"
    display_name = "CI/CD GitHub Actions Service Account"
    description  = "Service account for the CI/CD pipeline on GitHub Actions"
    roles = [
      "roles/artifactregistry.writer",
      "roles/run.admin",
      "roles/iam.serviceAccountUser"
    ]
  }
  # Add your custom service accounts here!
  custom_service = {
    account_id   = "custom-sa"
    display_name = "Custom Service Account"
    description  = "Custom service account for specific needs"
    roles = ["roles/storage.objectViewer"]
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

### Created Bucket

The infrastructure creates a single, unified Google Cloud Storage bucket for all data storage needs:

#### Sauter University Bucket
- **Name**: `bucket-sauter-university`
- **Purpose**: Unified storage for all university data including logs, raw data, processed data, and ML artifacts
- **URL**: `gs://bucket-sauter-university`

### Storage Configuration
- **Location**: `us-central1` (configurable via `region` variable)
- **Storage Class**: `STANDARD`
- **Versioning**: Enabled for data protection and version history
- **Force Destroy**: Enabled for easier management
- **Labels**: Now completely configurable via variables!
  - `environment: ${var.environment}` (configurable: development/staging/production)
  - `project: ${var.project_name}` (configurable project name)
  - `purpose: general` (can be customized per resource)
  - `managed_by: ${var.managed_by}` (configurable: terraform/manual/etc)
  - **Plus any custom labels** from `var.common_labels`

### Bucket Features
- **Versioning Enabled**: Automatic versioning for all objects
- **Public Access Prevention**: Enforced for security
- **Bucket Policy Only**: Enabled for consistent access control
- **Logging Integration**: All Cloud Logging sinks export to this bucket

### Usage Examples
```bash
# List bucket contents
gsutil ls gs://bucket-sauter-university/

# Upload data files
gsutil cp data.json gs://bucket-sauter-university/raw-data/
gsutil cp processed_data.json gs://bucket-sauter-university/processed-data/

# Upload ML models and artifacts
gsutil cp model.pkl gs://bucket-sauter-university/ml-models/

# Create organized folder structure
gsutil cp -r local_logs/ gs://bucket-sauter-university/logs/
gsutil cp -r datasets/ gs://bucket-sauter-university/datasets/
```

### Data Organization Strategy

With a single bucket, organize data using a clear folder structure:

```
bucket-sauter-university/
├── logs/                    # Application and infrastructure logs
│   ├── terraform/
│   ├── api/
│   └── audit/
├── raw-data/               # Unprocessed, original data
│   ├── reservoirs/
│   ├── sensors/
│   └── api-responses/
├── processed-data/         # Cleaned and transformed data
│   ├── reservoirs/
│   └── aggregated/
├── ml-models/              # Machine learning artifacts
│   ├── trained-models/
│   ├── training-data/
│   └── predictions/
└── backups/                # Data backups and archives
    ├── daily/
    └── weekly/
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

### Core Infrastructure Outputs

| Output | Description |
|--------|-------------|
| `project_id` | The GCP project ID |
| `project_number` | The GCP project number |
| `region` | The configured GCP region |
| `zone` | The configured GCP zone |
| `enabled_apis` | List of all enabled Google Cloud APIs |

### Budget and Monitoring Outputs

| Output | Description |
|--------|-------------|
| `budget_name` | The created budget name |
| `budget_id` | The created budget ID |
| `budget_amount` | The configured budget amount in BRL |
| `budget_alert_email` | The email address configured for budget alerts |
| `monitoring_notification_channel` | Email notification channel information |

### Storage and Data Outputs

| Output | Description |
|--------|-------------|
| `sauter_university_bucket` | Unified bucket information (name, URL, self_link) |
| `storage_buckets_summary` | Summary of the unified Cloud Storage bucket |
| `terraform_state_bucket_name` | Terraform state bucket name |
| `terraform_state_bucket_url` | Terraform state bucket URL |
| `terraform_backend_config` | Backend configuration values |
| `bigquery_dataset` | BigQuery dataset information (ID, URL, creation time) |

### Container Registry and Cloud Run Outputs

| Output | Description |
|--------|-------------|
| `artifact_registry_repository` | Artifact Registry repository information (ID, name, URL) |
| `api_service_url` | Cloud Run service URL for the deployed FastAPI |
| `api_service_name` | Cloud Run service name |
| `api_service_location` | Cloud Run service location/region |

### Service Account and Security Outputs

| Output | Description |
|--------|-------------|
| `cloud_run_api_service_account` | Cloud Run API service account information |
| `cloud_run_api_service_account_email` | Email of the Cloud Run API service account |
| `terraform_service_account` | Terraform service account information |
| `terraform_service_account_email` | Email of the Terraform service account |
| `cicd_service_account_email` | Email of the CI/CD service account |
| `all_service_accounts` | Information about all service accounts |
| `workload_identity_provider_name` | Full name of the Workload Identity Provider |

### Infrastructure Summary

| Output | Description |
|--------|-------------|
| `infrastructure_summary` | Complete summary of all provisioned infrastructure |

### Accessing Output Values

#### Basic Output Commands
```bash
# View all outputs
terraform output

# View infrastructure summary
terraform output infrastructure_summary

# View all service accounts
terraform output all_service_accounts
```

#### API and Service Information
```bash
# Get FastAPI service URL
terraform output api_service_url
# Output: https://sauter-api-hub-mh6f7nhi4q-uc.a.run.app

# Get API service details
terraform output api_service_name
terraform output api_service_location

# Test the API
curl $(terraform output -raw api_service_url)
curl $(terraform output -raw api_service_url)/docs
```

#### Container Registry Information
```bash
# Get repository URL for Docker commands
terraform output -json artifact_registry_repository | jq -r '.repository_url'

# Build complete image path
echo "$(terraform output -json artifact_registry_repository | jq -r '.repository_url')/sauter-reservoir-api:latest"
```

#### Storage and Data Access
```bash
# Get unified bucket information
terraform output sauter_university_bucket

# Get bucket URL for gsutil commands  
terraform output -json sauter_university_bucket | jq -r '.url'

# Access bucket directly
gsutil ls $(terraform output -json sauter_university_bucket | jq -r '.url')

# BigQuery dataset information
terraform output bigquery_dataset
terraform output -json bigquery_dataset | jq -r '.dataset_id'
```

#### Service Account and Security
```bash
# Get Cloud Run API service account
terraform output cloud_run_api_service_account_email

# Get CI/CD service account for GitHub Actions
terraform output cicd_service_account_email

# Get Workload Identity Provider for GitHub setup
terraform output workload_identity_provider_name

# Get Terraform service account
terraform output terraform_service_account_email
```

#### Budget and Monitoring
```bash
# Check budget configuration
terraform output budget_amount
terraform output budget_alert_email

# Get notification channel details
terraform output monitoring_notification_channel
```

#### Backend and State Management
```bash
# Get backend configuration
terraform output terraform_backend_config

# Get state bucket information
terraform output terraform_state_bucket_name
terraform output terraform_state_bucket_url
```

## 🏆 Terraform Best Practices Implementation

### ✅ **What We've Achieved**

This infrastructure now implements **100% Terraform best practices**:

#### **1. Zero Hardcoded Values** 
- ❌ **Before**: Hardcoded API lists, service account configurations, labels
- ✅ **Now**: Everything configurable via variables

#### **2. Complete Variable Coverage**
- 🎯 **25+ new variables** covering every configuration aspect
- 🔧 **Proper typing** (string, number, bool, list, map, object)
- 📝 **Comprehensive descriptions** for all variables
- 🎛️ **Sensible defaults** for development environments

#### **3. Environment-Specific Configuration**
- 🌍 **Multi-environment support** (dev/staging/prod)
- 🔀 **Environment-specific variable files**
- 🏷️ **Consistent labeling** across environments
- ⚙️ **Feature toggles** for optional components

#### **4. Advanced Configuration Patterns**
- 📦 **Complex object variables** for service accounts
- 🔀 **Dynamic resource creation** with for_each loops
- 🏷️ **Merge function** for consistent labeling
- 🎛️ **Feature flags** for enabling/disabling components

### 📁 **New File Structure**
```
src/terraform/
├── main.tf                          # ✅ 100% variable-driven
├── variables.tf                     # ✅ 25+ comprehensive variables  
├── outputs.tf                       # ✅ Comprehensive outputs
├── terraform.tfvars.example         # ✅ NEW - Complete example config
├── TERRAFORM_BEST_PRACTICES.md      # ✅ NEW - Implementation guide
└── modules/                         # ✅ Updated to use variables
```

### 🎯 **Key Improvements**

#### **Variables Coverage**
```hcl
# Before: Hardcoded
resource "google_project_service" "apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",  # ❌ Hardcoded
    "bigquery.googleapis.com",          # ❌ Hardcoded
    # ... more hardcoded values
  ])
}

# After: 100% Variable-Driven  
resource "google_project_service" "apis" {
  for_each = var.enable_apis ? toset(var.required_apis) : toset([])  # ✅ Variables!
}
```

#### **Labels Standardization**
```hcl
# Before: Hardcoded labels everywhere
labels = {
  environment = "development"  # ❌ Hardcoded
  project     = "sauter-university"  # ❌ Hardcoded
  managed_by  = "terraform"    # ❌ Hardcoded
}

# After: Consistent variable-driven labels
labels = merge(var.common_labels, {
  environment = var.environment      # ✅ Variable
  project     = var.project_name     # ✅ Variable  
  purpose     = "specific-purpose"   # ✅ Contextual
  managed_by  = var.managed_by       # ✅ Variable
})
```

### 🚀 **Benefits Achieved**

1. **🔧 Easy Environment Management**
   ```bash
   # Development
   terraform apply
   
   # Production  
   terraform apply -var-file="production.tfvars"
   
   # Custom configuration
   terraform apply -var="environment=staging"
   ```

2. **🎛️ Feature Toggle Control**
   ```hcl
   enable_apis = false              # Skip API enablement
   enable_notifications = false     # Skip budget alerts
   enable_bucket_force_destroy = true  # Allow deletion in dev
   ```

3. **🏷️ Consistent Resource Labeling**
   ```hcl
   common_labels = {
     team        = "data-engineering"
     cost-center = "engineering" 
     owner       = "sauter-university"
     compliance  = "required"
   }
   ```

4. **🔐 Flexible Service Account Management**
   ```hcl
   # Add new service accounts easily
   service_accounts_config = {
     existing_accounts = { ... }
     new_ml_service = {
       account_id = "ml-pipeline-sa"
       roles = ["roles/ml.admin", "roles/storage.admin"]
     }
   }
   ```

### 📋 **Validation Checklist**

- ✅ **Zero hardcoded values** in main.tf
- ✅ **All strings/numbers/bools** are variables
- ✅ **Environment-specific** configurations  
- ✅ **Consistent labeling** across all resources
- ✅ **Feature toggles** for optional components
- ✅ **Complex object variables** for advanced config
- ✅ **terraform.tfvars.example** provided
- ✅ **Comprehensive documentation** updated
- ✅ **terraform fmt** passes
- ✅ **terraform validate** passes

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
- `roles/monitoring.admin` - For alert policies and notification channels
- `roles/serviceusage.serviceUsageAdmin` - For API management and enablement
- `roles/resourcemanager.projectIamAdmin` - For project-level IAM changes
- `roles/iam.serviceAccountAdmin` - For creating and managing service accounts
- `roles/storage.admin` - For creating and managing Cloud Storage buckets
- `roles/bigquery.admin` - For creating and managing BigQuery datasets
- `roles/artifactregistry.admin` - For creating and managing Artifact Registry repositories
- `roles/run.admin` - For creating and managing Cloud Run services
- `roles/logging.admin` - For creating and managing logging sinks

## � Workload Identity Federation (CI/CD Integration)

### Secure GitHub Actions Authentication

The infrastructure includes Workload Identity Federation (WIF) for secure, keyless authentication between GitHub Actions and Google Cloud Platform.

#### WIF Configuration Details
- **Workload Identity Pool**: GitHub Actions Pool
- **Identity Provider**: GitHub Actions Provider  
- **Issuer URI**: `https://token.actions.githubusercontent.com`
- **Repository**: `Sauter-University/sauter-university-2025-challenge`
- **Service Account**: `ci-cd-github-sa@sauter-university-472416.iam.gserviceaccount.com`

#### Key Benefits
- **🔑 Keyless Authentication**: No need to store service account keys in GitHub secrets
- **🛡️ Enhanced Security**: Short-lived tokens instead of long-lived credentials
- **🎯 Repository-Scoped**: Access limited to specific GitHub repository
- **🚀 CI/CD Ready**: Direct integration with GitHub Actions workflows

#### CI/CD Service Account Permissions
The `ci_cd` service account has minimal required permissions:
- `roles/artifactregistry.writer` - Push container images to registry
- `roles/run.admin` - Deploy and manage Cloud Run services  
- `roles/iam.serviceAccountUser` - Impersonate other service accounts when needed

#### Attribute Mapping
```hcl
attribute_mapping = {
  "google.subject"       = "assertion.sub"
  "attribute.actor"      = "assertion.actor" 
  "attribute.repository" = "assertion.repository"
}

# Repository restriction
attribute_condition = "attribute.repository == 'Sauter-University/sauter-university-2025-challenge'"
```

#### Usage in GitHub Actions
```yaml
# Example GitHub Actions workflow step
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ci-cd-github-sa@sauter-university-472416.iam.gserviceaccount.com

- name: Build and Push Container
  run: |
    gcloud builds submit --tag us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:${{ github.sha }}
    
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy sauter-api-hub \
      --image us-central1-docker.pkg.dev/sauter-university-472416/sauter-university-docker-repo/sauter-reservoir-api:${{ github.sha }} \
      --region us-central1
```

#### Required GitHub Secrets
```bash
# Only one secret needed (no service account keys!)
WIF_PROVIDER: projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
```

#### Security Best Practices Implemented
- ✅ **No Service Account Keys**: Uses OIDC tokens instead
- ✅ **Repository Scoping**: Access limited to specific GitHub repo  
- ✅ **Minimal Permissions**: Least-privilege access model
- ✅ **Attribute Validation**: Validates GitHub repository ownership
- ✅ **Short-Lived Tokens**: Temporary authentication tokens

#### Terraform Configuration Example
```hcl
module "wif" {
  source = "./modules/wif"

  project_id           = var.project_id
  service_account_name = module.iam.service_account_names["ci_cd"]
  github_repository    = var.github_repository  # "Sauter-University/sauter-university-2025-challenge"
}
```

## �📚 Additional Resources

### 🎯 **This Project's Documentation**
- [**TERRAFORM_BEST_PRACTICES.md**](TERRAFORM_BEST_PRACTICES.md) - ⭐ **NEW** - Complete implementation guide
- [**terraform.tfvars.example**](terraform.tfvars.example) - ⭐ **NEW** - Example configuration file
- [**Cloud Storage Module README**](modules/cloud_storage/README.md) - Detailed bucket documentation

### 🌐 **Official Documentation** 
- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Cloud Run Documentation](https://cloud.google.com/run/docs)
- [GCP Billing Budgets API](https://cloud.google.com/billing/docs/how-to/budgets)
- [GCP Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions with GCP](https://github.com/google-github-actions/auth)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)

### 🏆 **Best Practices Resources**
- [HashiCorp Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform)
- [Google Cloud Terraform Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform)
- [Terraform Variable Best Practices](https://www.terraform.io/docs/language/values/variables.html)

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test locally
3. Run `terraform plan` to verify changes
4. Submit pull request with detailed description
5. Ensure all checks pass before merging


---

## 🎉 **Congratulations!** 

This infrastructure now implements **100% Terraform best practices** with:
- ✅ **Zero hardcoded values** 
- ✅ **Complete variable coverage**
- ✅ **Environment-specific configurations**
- ✅ **Industry-standard patterns**

---

## 📋 Summary

This **Sauter University Reservoir Data Management System** provides a complete, production-ready infrastructure for:

### 🌊 **Reservoir Data Management**
- ✅ Automated data ingestion from Brazil's ONS (National System Operator)
- ✅ FastAPI-based REST API for data access and management
- ✅ BigQuery data warehouse for analytics and reporting
- ✅ Unified Cloud Storage for all data types

### 🏗️ **Cloud-Native Architecture**  
- ✅ Serverless deployment with Cloud Run (auto-scaling, pay-per-use)
- ✅ Container-based deployment with Artifact Registry
- ✅ Secure CI/CD with Workload Identity Federation
- ✅ Comprehensive monitoring and budget alerts

### 🔧 **Infrastructure as Code Excellence**
- ✅ **100% Terraform best practices** implemented
- ✅ **Zero hardcoded values** - everything configurable via variables
- ✅ **Multi-environment support** (dev/staging/production)
- ✅ **Complete documentation** and examples provided

### 🛡️ **Enterprise Security**
- ✅ **Principle of least privilege** for all service accounts
- ✅ **Keyless authentication** with Workload Identity Federation
- ✅ **Repository-scoped access** for CI/CD pipelines
- ✅ **Secure state management** with remote GCS backend

**Note**: This infrastructure is designed for the Sauter University 2025 Challenge following industry best practices. All configurations are fully customizable via variables - modify `terraform.tfvars` according to your specific requirements and security policies.

**🚀 Ready for production deployment with enterprise-grade Terraform configuration!**