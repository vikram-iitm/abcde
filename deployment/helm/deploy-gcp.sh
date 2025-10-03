#!/bin/bash

# GCP Deployment Script for Onyx
# This script deploys Onyx to Google Kubernetes Engine

set -e

# Configuration
PROJECT_ID="onyx-test-ramdev-live"
CLUSTER_NAME="onyx-cluster"
ZONE="asia-south1-a"
NAMESPACE="onyx"
CHART_PATH="./charts/onyx"
RELEASE_NAME="onyx-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting GCP deployment for Onyx...${NC}"

# Check if gcloud is configured
echo -e "${YELLOW}📋 Checking GCP configuration...${NC}"
gcloud config get-value project &>/dev/null || {
    echo -e "${RED}❌ GCP project not configured. Please run: gcloud config set project $PROJECT_ID${NC}"
    exit 1
}

CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Switching to project: $PROJECT_ID${NC}"
    gcloud config set project $PROJECT_ID
fi

# Get GKE credentials
echo -e "${YELLOW}🔧 Getting GKE credentials...${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Create namespace if it doesn't exist
echo -e "${YELLOW}📦 Creating namespace: $NAMESPACE${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add GCP-specific values to the GCP values file
echo -e "${YELLOW}📝 Updating GCP values file...${NC}"
cat > $CHART_PATH/values-gcp-secrets.yaml << EOF
# Generated secret values for GCP deployment
# DO NOT COMMIT THIS FILE TO VERSION CONTROL

# Database configuration
externalPostgresql:
  password: "$(openssl rand -base64 32)"
  readonlyUser: "db_readonly_user"
  readonlyPassword: "$(openssl rand -base64 32)"

# Redis configuration (if password protected)
externalRedis:
  password: ""

# Google OAuth configuration
googleOAuth:
  clientId: "your-google-oauth-client-id"
  clientSecret: "your-google-oauth-client-secret"

# Application configuration
auth:
  secret: "$(openssl rand -base64 64)"

# Model servers configuration
modelServers:
  openaiApiKey: ""

# Additional secret environment variables
secretEnv: {}

# Cloud Storage service account key (if needed)
storage:
  serviceAccountKey: ""
EOF

echo -e "${YELLOW}⚠️  Generated secrets file: $CHART_PATH/values-gcp-secrets.yaml${NC}"
echo -e "${YELLOW}⚠️  Please update this file with actual values before deploying!${NC}"

# Deploy using Helm
echo -e "${YELLOW}🎯 Deploying Onyx with Helm...${NC}"
helm dependency update $CHART_PATH

# First, deploy with secrets
echo -e "${YELLOW}🔐 Deploying secrets...${NC}"
helm upgrade --install $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --values $CHART_PATH/values-gcp.yaml \
    --values $CHART_PATH/values-gcp-secrets.yaml \
    --wait \
    --timeout=10m

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"

# Get the status
echo -e "${YELLOW}📊 Getting deployment status...${NC}"
kubectl get all -n $NAMESPACE

echo -e "${GREEN}🎉 GCP deployment complete!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}1. Update the values-gcp-secrets.yaml file with actual OAuth credentials${NC}"
echo -e "${YELLOW}2. Monitor the deployment: kubectl get pods -n $NAMESPACE -w${NC}"
echo -e "${YELLOW}3. Check logs: kubectl logs -f deployment/<deployment-name> -n $NAMESPACE${NC}"
echo -e "${YELLOW}4. Access the application at: https://ramdev.live${NC}"