#!/bin/bash

# Cloud Run Deployment Script for Sauter University API
# This script builds and deploys the Python API to Cloud Run

set -e

# Configuration
PROJECT_ID="sauter-university-472416"
REGION="us-central1"
REPOSITORY_ID="sauter-university-docker-repo"
SERVICE_NAME="sauter-reservoir-api"
IMAGE_TAG="latest"

# Derived variables
REPOSITORY_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}"
IMAGE_URL="${REPOSITORY_URL}/${SERVICE_NAME}:${IMAGE_TAG}"

echo "🚀 Starting deployment process..."
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service Name: ${SERVICE_NAME}"
echo "Image URL: ${IMAGE_URL}"

# Check if gcloud is authenticated
echo "🔍 Checking gcloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
    echo "❌ No active gcloud authentication found. Please run: gcloud auth login"
    exit 1
fi

# Configure Docker to use gcloud as a credential helper
echo "🔧 Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# Build the Docker image
echo "🏗️ Building Docker image..."
docker build -t ${IMAGE_URL} .

# Push the image to Artifact Registry
echo "📤 Pushing image to Artifact Registry..."
docker push ${IMAGE_URL}

# Deploy to Cloud Run (this will be handled by Terraform, but kept for manual deployment if needed)
echo "🌟 Image pushed successfully!"
echo "📋 To deploy via Terraform, run:"
echo "   cd src/terraform"
echo "   terraform apply"
echo ""
echo "📋 To deploy manually via gcloud, run:"
echo "   gcloud run deploy ${SERVICE_NAME} \\"
echo "     --image=${IMAGE_URL} \\"
echo "     --platform=managed \\"
echo "     --region=${REGION} \\"
echo "     --allow-unauthenticated \\"
echo "     --service-account=cloud-run-api-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "✅ Deployment script completed successfully!"