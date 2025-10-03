# Google Cloud Shell Build Guide

## Access Cloud Shell
1. Go to https://console.cloud.google.com
2. Click Cloud Shell icon (>_ ) in top right
3. Select project: `onyx-test-ramdev-live`

## Step 1: Setup Environment
```bash
# Clone the repository
git clone https://github.com/your-repo/onyx.git
cd onyx

# Verify setup
./deployment/cloud-shell-setup.sh

# Install Node.js 20 (for web server build)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js version
node --version
npm --version
```

## Step 2: Build API Container
```bash
# Navigate to project root
cd /path/to/onyx

# Build API container
export DOCKER_BUILDKIT=0
cd backend
docker build -f Dockerfile -t gcr.io/onyx-test-ramdev-live/api:latest --platform linux/amd64 --build-arg COMMIT_SHA=$(git rev-parse HEAD) .

# Push to GCR
docker push gcr.io/onyx-test-ramdev-live/api:latest
```

## Step 3: Build Web Server Container
```bash
# Navigate to web directory
cd ../web

# Build web server container
export DOCKER_BUILDKIT=0
docker build -f Dockerfile -t gcr.io/onyx-test-ramdev-live/webserver:latest --platform linux/amd64 --build-arg COMMIT_SHA=$(git rev-parse HEAD) .

# Push to GCR
docker push gcr.io/onyx-test-ramdev-live/webserver:latest
```

## Step 4: Update Kubernetes Deployments
```bash
# Get cluster credentials
gcloud container clusters get-credentials onyx-cluster --region asia-south1 --project onyx-test-ramdev-live

# Update API server deployment
kubectl set image deployment/onyx-stack-api-server api-server=gcr.io/onyx-test-ramdev-live/api:latest -n onyx

# Update web server deployment
kubectl set image deployment/onyx-stack-web-server web-server=gcr.io/onyx-test-ramdev-live/webserver:latest -n onyx

# Watch pod status
kubectl get pods -n onyx -w
```

## Step 5: Verify Deployment
```bash
# Check all pods
kubectl get pods -n onyx

# Check pod logs if needed
kubectl logs deployment/onyx-stack-api-server -n onyx
kubectl logs deployment/onyx-stack-web-server -n onyx

# Check ingress status
kubectl get ingress -n onyx
```

## Troubleshooting
- If Docker BuildKit issues, use: `export DOCKER_BUILDKIT=0`
- If GCR authentication issues, run: `gcloud auth configure-docker gcr.io`
- If cluster access issues, verify project and region settings