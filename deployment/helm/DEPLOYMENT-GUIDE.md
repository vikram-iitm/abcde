# Onyx GCP Deployment Guide

## 📋 Prerequisites

### 1. Google OAuth Setup (REQUIRED)
Before deploying, you must set up Google OAuth credentials:

1. **Enable Required APIs:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to **APIs & Services > Library**
   - Enable: **OAuth 2.0 API** and **Identity Toolkit API**

2. **Create OAuth Client ID:**
   - Go to **APIs & Services > Credentials**
   - Click **"+ CREATE CREDENTIALS"** > **"OAuth client ID"**
   - **Application type**: Web application
   - **Name**: "Onyx Production"
   - **Authorized redirect URIs**:
     - `https://ramdev.live/auth`
     - `https://ramdev.live/api/auth/callback`
   - Click **"CREATE"**
   - Copy the **Client ID** and **Client Secret**

3. **Update Secrets File:**
   Edit `deployment/helm/charts/onyx/values-gcp-secrets.yaml`:
   ```yaml
   googleOAuth:
     clientId: "YOUR_ACTUAL_CLIENT_ID_HERE"
     clientSecret: "YOUR_ACTUAL_CLIENT_SECRET_HERE"
   ```

### 2. Install Required Tools

```bash
# Install Helm
brew install helm

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Update PATH for auth plugin
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
```

## 🚀 Deployment Steps

### Step 1: Get GKE Credentials

```bash
gcloud container clusters get-credentials onyx-cluster --zone asia-south1-a
```

### Step 2: Create Namespace

```bash
kubectl create namespace onyx
```

### Step 3: Update Helm Dependencies

```bash
cd deployment/helm
helm dependency update ./charts/onyx
```

### Step 4: Deploy with Helm

```bash
helm upgrade --install onyx-stack ./charts/onyx \
    --namespace onyx \
    --values ./charts/onyx/values-gcp.yaml \
    --values ./charts/onyx/values-gcp-secrets.yaml \
    --wait \
    --timeout=15m
```

### Step 5: Verify Deployment

```bash
# Check all resources
kubectl get all -n onyx

# Check pods specifically
kubectl get pods -n onyx

# Check migrations job
kubectl get jobs -n onyx

# Check ingress
kubectl get ingress -n onyx

# Check managed certificates
kubectl get managedcertificate -n onyx
```

## 🔍 Troubleshooting

### Common Issues

1. **kubectl connection issues:**
   ```bash
   # Ensure auth plugin is in PATH
   export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"

   # Re-fetch credentials
   gcloud container clusters get-credentials onyx-cluster --zone asia-south1-a
   ```

2. **Pod stuck in pending:**
   ```bash
   # Check node resources
   kubectl describe nodes

   # Check pod events
   kubectl describe pod <pod-name> -n onyx
   ```

3. **Database connection errors:**
   ```bash
   # Check migration job logs
   kubectl logs job/onyx-stack-db-migrate -n onyx

   # Check if migrations completed
   kubectl get jobs -n onyx
   ```

4. **OAuth not working:**
   ```bash
   # Verify OAuth credentials are set correctly
   kubectl get secret onyx-stack-gcp-secrets -n onyx -o yaml

   # Check web server logs for OAuth errors
   kubectl logs deployment/onyx-stack-webserver -n onyx
   ```

## 📊 Monitoring

### Health Checks

```bash
# Application health
kubectl logs deployment/onyx-stack-api -n onyx | grep -i health

# Database connectivity
kubectl logs deployment/onyx-stack-api -n onyx | grep -i database

# Redis connectivity
kubectl logs deployment/onyx-stack-api -n onyx | grep -i redis
```

### SSL Certificate Status

```bash
# Check managed certificate
kubectl get managedcertificate -n onyx

# Check GCP certificate status
gcloud compute ssl-certificates describe onyx-ssl-cert --global

# Check ingress status
kubectl get ingress onyx-stack-ingress-gcp -n onyx
```

## 🎯 Accessing the Application

Once deployed successfully:

- **Main Application**: https://ramdev.live
- **API Endpoints**: https://ramdev.live/api/*
- **Health Check**: https://ramdev.live/health

## 🔄 Scaling Configuration

The deployment is configured for a small team (2-3 users). To adjust scaling:

1. **Horizontal Pod Autoscaler** - Already configured in values-gcp.yaml
2. **Resource Limits** - Adjust in values-gcp.yaml under each component
3. **Node Pool Autoscaling** - Currently 1-3 nodes per pool

## 📈 Production Considerations

### Before Production Use:

1. **SSL Certificate**: Ensure managed certificate is active
2. **Backups**: Verify Cloud SQL automated backups are enabled
3. **Monitoring**: Set up Cloud Monitoring alerts
4. **Security**: Review all security configurations
5. **Performance**: Test with expected user load

### Security Checklist:

- [ ] Google OAuth credentials are properly configured
- [ ] Database passwords are secure and not default values
- [ ] SSL/TLS is enforced for all connections
- [ ] Private network access is properly configured
- [ ] Service account permissions are minimal and specific
- [ ] Secrets are not committed to version control

## 🆘 Support

If you encounter issues:

1. **Application Logs**: `kubectl logs -f deployment/<name> -n onyx`
2. **GCP Console**: Check Cloud Logging and Monitoring
3. **GKE Dashboard**: Check cluster and pod status
4. **Load Balancer**: Check GCP Load Balancer health checks
5. **DNS**: Verify DNS propagation is complete

## 📝 Post-Deployment Tasks

1. **Create Admin User**: Use the application's user creation interface
2. **Test All Features**: Verify search, chat, and document upload work
3. **Set Up Monitoring**: Configure alerts for critical metrics
4. **Configure Backups**: Verify automated backup schedules
5. **Performance Test**: Test with expected user load