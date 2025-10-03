#!/bin/bash

# Cloud Shell Setup Script for Onyx Container Builds
# Project: onyx-test-ramdev-live

echo "=== Google Cloud Shell Setup ==="
echo "Project: onyx-test-ramdev-live"
echo "Date: $(date)"
echo ""

# Verify project and authentication
echo "1. Verifying Google Cloud project..."
gcloud config get-value project
echo ""

# Check available disk space
echo "2. Checking Cloud Shell disk space..."
df -h / | head -2
echo ""

# Verify Docker availability
echo "3. Checking Docker installation..."
docker --version
echo ""

# Check GCR authentication
echo "4. Verifying GCR authentication..."
gcloud auth configure-docker gcr.io --quiet
echo ""

# Verify kubectl access to cluster
echo "5. Checking GKE cluster access..."
gcloud container clusters describe onyx-cluster --region asia-south1 2>/dev/null && echo "✅ Cluster accessible" || echo "❌ Cluster access issue"
echo ""

echo "=== Setup Complete ==="
