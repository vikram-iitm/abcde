# GCP Deployment Guide for Onyx

This guide explains how to deploy Onyx on Google Cloud Platform using the provided Helm charts.

## Prerequisites

1. **GCP Project**: `onyx-test-ramdev-live`
2. **GKE Cluster**: `onyx-cluster` in `asia-south1-a`
3. **Managed Services**:
   - Cloud SQL PostgreSQL: `10.72.0.3:5432`
   - Memorystore Redis: `10.72.1.4:6379`
   - Cloud Storage buckets configured
4. **Domain**: `ramdev.live` with DNS configured
5. **SSL Certificate**: Managed certificate provisioning

## Deployment Steps

### 1. Update Secrets Configuration

Copy and edit the secrets file:

```bash
cp deployment/helm/charts/onyx/values-gcp-secrets.yaml.template deployment/helm/charts/onyx/values-gcp-secrets.yaml
```

Update the following values in `values-gcp-secrets.yaml`:

```yaml
# Google OAuth Configuration (Required)
googleOAuth:
  clientId: "your-google-oauth-client-id"
  clientSecret: "your-google-oauth-client-secret"

# Database passwords (keep generated values or set your own)
externalPostgresql:
  password: "your-secure-postgres-password"
  readonlyPassword: "your-secure-readonly-password"

# Application secret (keep generated value)
auth:
  secret: "your-generated-secret-key"
```

### 2. Set Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services > Credentials
3. Create OAuth 2.0 Client ID
4. Application type: Web application
5. Authorized redirect URIs:
   - `https://ramdev.live/auth`
   - `https://ramdev.live/api/auth/callback`
6. Copy Client ID and Client Secret to secrets file

### 3. Deploy the Application

Run the deployment script:

```bash
cd deployment/helm
./deploy-gcp.sh
```

Or deploy manually:

```bash
# Set up GCP credentials
gcloud container clusters get-credentials onyx-cluster --zone asia-south1-a

# Create namespace
kubectl create namespace onyx

# Deploy with Helm
helm dependency update ./charts/onyx
helm upgrade --install onyx-stack ./charts/onyx \
    --namespace onyx \
    --values ./charts/onyx/values-gcp.yaml \
    --values ./charts/onyx/values-gcp-secrets.yaml \
    --wait
```

### 4. Monitor Deployment

```bash
# Check pod status
kubectl get pods -n onyx

# Watch deployment progress
kubectl get pods -n onyx -w

# Check specific pod logs
kubectl logs -f deployment/onyx-stack-api -n onyx
kubectl logs -f deployment/onyx-stack-webserver -n onyx
```

## Configuration Options

### Database Configuration

The deployment uses external Cloud SQL database:
- Host: `10.72.0.3`
- Port: `5432`
- Database: `onyx`
- Username: `postgres`

### Redis Configuration

Uses external Memorystore:
- Host: `10.72.1.4`
- Port: `6379`
- No password (for internal deployment)

### Storage Configuration

Cloud Storage buckets:
- File store: `onyx-file-store-ramdev-123456`
- Logs: `onyx-logs-ramdev-123456`
- Backups: `onyx-backups-ramdev-123456`

### Resource Allocation

**Default Node Pools:**
- General purpose: 2x e2-medium (2 vCPU, 4GB RAM)
- Memory optimized: 1x e2-highmem-2 (2 vCPU, 16GB RAM)

**Pod Resources:**
- Webserver: 200m-1000m CPU, 512Mi-1Gi RAM
- API: 300m-1500m CPU, 768Mi-2Gi RAM
- Celery workers: Various based on type
- Vespa: 500m-2000m CPU, 2Gi-4Gi RAM (memory-optimized nodes)

## Accessing the Application

Once deployed, the application will be available at:
- **Main Application**: https://ramdev.live
- **API endpoints**: https://ramdev.live/api/*

## Troubleshooting

### Common Issues

1. **Pods stuck in pending state**
   - Check node resources: `kubectl describe nodes`
   - Verify autoscaling is working properly

2. **Database connection errors**
   - Verify Cloud SQL private IP connectivity
   - Check database credentials in secrets

3. **SSL certificate issues**
   - Check managed certificate status: `kubectl get managedcertificate -n onyx`
   - Verify DNS propagation is complete

4. **Google OAuth errors**
   - Verify OAuth client ID and secret are correct
   - Check redirect URIs in Google Cloud Console

### Useful Commands

```bash
# Get all resources in namespace
kubectl get all -n onyx

# Check ingress status
kubectl get ingress -n onyx

# Check managed certificate
kubectl get managedcertificate -n onyx

# Check certificate status
gcloud compute ssl-certificates describe onyx-ssl-cert --global

# View pod events
kubectl get events -n onyx

# Port forward for debugging
kubectl port-forward -n onyx deployment/onyx-stack-api 8080:8080
```

## Scaling Configuration

The deployment is configured for a small team (2-3 users). To scale up:

1. **Vertical Scaling**: Update resource limits in `values-gcp.yaml`
2. **Horizontal Scaling**: Enable autoscaling or adjust replica counts
3. **Database**: Upgrade Cloud SQL instance tier
4. **Storage**: Increase Cloud Storage bucket sizes

## Backup and Recovery

### Database Backups
Cloud SQL is configured with automated daily backups. To restore:

```bash
# List backups
gcloud sql backups list --instance=onyx-db

# Restore from backup
gcloud sql backups restore [BACKUP_ID] --instance=onyx-db --restore-instance=onyx-db-restore
```

### Application Backups
Application configuration and data are backed up to Cloud Storage automatically.

## Monitoring

### Google Cloud Monitoring
- Operations Suite is enabled
- Cloud Logging is configured
- Cloud Monitoring dashboards are available

### Health Checks
- Application health endpoint: `/health`
- Database connectivity checks
- Redis connectivity checks

## Support

For issues or questions:
1. Check Google Cloud Console logs
2. Review GKE logs and metrics
3. Check application logs in Cloud Logging
4. Verify all prerequisites are met