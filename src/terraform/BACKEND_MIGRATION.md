# Remote Backend Migration Guide

This guide helps you migrate from local Terraform state to remote Google Cloud Storage backend.

## 🎯 Overview

The Terraform configuration now includes a remote backend using Google Cloud Storage to:
- Store state files securely in the cloud
- Enable team collaboration
- Provide state locking and versioning
- Prevent state file conflicts

## 📋 Migration Steps

### Step 1: Current State Backup (Important!)
Before starting the migration, backup your current local state:

```bash
# Backup current local state
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
```

### Step 2: Initialize and Create State Bucket
Since the state bucket is managed by Terraform itself, we need a two-phase approach:

```bash
# Navigate to terraform directory
cd src/terraform

# First, create the state bucket (one-time setup)
terraform init
terraform apply -target=module.terraform_state_bucket

# Confirm the creation when prompted
```

### Step 3: Migrate to Remote Backend
After the bucket is created, migrate to use the remote backend:

```bash
# Reinitialize with remote backend
terraform init

# You will be prompted about migrating state - type 'yes'
# The prompt will look like:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### Step 4: Verify Migration
Verify that the migration was successful:

```bash
# Check that state is now remote
terraform show

# Verify the state bucket contains your state
gsutil ls gs://sauter-university-472416-terraform-state/terraform/state/
```

### Step 5: Clean up local state (Optional)
After successful migration and verification:

```bash
# Remove local state files (they're now in the cloud)
rm terraform.tfstate terraform.tfstate.backup
```

## 🔧 Alternative Methods

### Method 2: Using Backend Configuration File
You can also initialize using the backend configuration file:

```bash
terraform init -backend-config=backend.hcl
```

### Method 3: Manual Backend Configuration
If you prefer to configure the backend manually:

```bash
terraform init
# When prompted for backend configuration:
# bucket: sauter-university-472416-terraform-state  
# prefix: terraform/state
```

## 🔍 Verification Commands

### Check Backend Status
```bash
# Show current backend configuration
terraform init -backend=false
terraform show
```

### List State Files in Cloud
```bash
# List all state files in the remote bucket
gsutil ls -r gs://sauter-university-472416-terraform-state/
```

### View State File Versions
```bash
# List versions of state files (versioning is enabled)
gsutil ls -a gs://sauter-university-472416-terraform-state/terraform/state/
```

## ⚠️ Important Notes

1. **State Bucket Protection**: The state bucket has `force_destroy = false` to prevent accidental deletion
2. **Versioning Enabled**: State file versioning is enabled for recovery purposes
3. **Team Collaboration**: Multiple team members can now work with the same state
4. **Backup Strategy**: Regular backups are automatically handled by GCS versioning

## 🚨 Troubleshooting

### Issue: "Backend initialization required"
```bash
terraform init -reconfigure
```

### Issue: State conflicts during migration
```bash
# Force reinitialize (use with caution)
terraform init -force-copy
```

### Issue: Cannot access state bucket
Ensure you have the correct GCP permissions:
```bash
# Check your current authentication
gcloud auth list

# Check project permissions
gcloud projects get-iam-policy sauter-university-472416
```

## 📁 Configuration Files

The remote backend configuration involves these files:
- `main.tf` - Contains the backend configuration in the terraform block
- `backend.hcl` - Optional backend configuration file for initialization
- `backend.tf` - Documentation file explaining the configuration
- `variables.tf` - Contains backend-related variables
- `terraform.tfvars` - Contains the actual backend values

## 🔐 Security Considerations

- The state bucket is in the same project for simplified IAM
- Bucket versioning provides state history and recovery
- No force destroy prevents accidental state loss
- Access is controlled via GCP IAM policies