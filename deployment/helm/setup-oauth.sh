#!/bin/bash

# Google OAuth setup script for Onyx
# This script helps set up Google OAuth credentials

set -e

# Configuration
PROJECT_ID="onyx-test-ramdev-live"
DOMAIN="ramdev.live"
REDIRECT_URIS=(
    "https://ramdev.live/auth"
    "https://ramdev.live/api/auth/callback"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Google OAuth Setup for Onyx${NC}"
echo -e "${YELLOW}This script will guide you through setting up Google OAuth credentials.${NC}"
echo ""

# Check if gcloud is configured
echo -e "${YELLOW}📋 Checking GCP configuration...${NC}"
if ! gcloud config get-value project &>/dev/null; then
    echo -e "${RED}❌ GCP project not configured. Please run: gcloud config set project $PROJECT_ID${NC}"
    exit 1
fi

CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo -e "${YELLOW}⚠️  Current project is $CURRENT_PROJECT, switching to $PROJECT_ID${NC}"
    gcloud config set project $PROJECT_ID
fi

echo -e "${GREEN}✅ GCP project configured: $PROJECT_ID${NC}"

# Check if required APIs are enabled
echo -e "${YELLOW}🔍 Checking required APIs...${NC}"
REQUIRED_APIS=("identitytoolkit.googleapis.com" "oauth2.googleapis.com")
for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --filter="name:$api" | grep -q "$api"; then
        echo -e "${GREEN}✅ $api is enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  $api is not enabled, enabling...${NC}"
        gcloud services enable "$api"
        echo -e "${GREEN}✅ $api enabled${NC}"
    fi
done

# Instructions for creating OAuth credentials
echo ""
echo -e "${BLUE}📋 Steps to create Google OAuth credentials:${NC}"
echo ""

echo -e "${YELLOW}1. Open Google Cloud Console:${NC}"
echo -e "${BLUE}   https://console.cloud.google.com/apis/credentials${NC}"
echo ""

echo -e "${YELLOW}2. Select project: $PROJECT_ID${NC}"
echo ""

echo -e "${YELLOW}3. Click '+ CREATE CREDENTIALS' > 'OAuth client ID'${NC}"
echo ""

echo -e "${YELLOW}4. Application type: 'Web application'${NC}"
echo ""

echo -e "${YELLOW}5. Name: 'Onyx Production'${NC}"
echo ""

echo -e "${YELLOW}6. Authorized redirect URIs:${NC}"
for uri in "${REDIRECT_URIS[@]}"; do
    echo -e "${BLUE}   - $uri${NC}"
done
echo ""

echo -e "${YELLOW}7. Click 'CREATE'${NC}"
echo ""

echo -e "${YELLOW}8. Copy the Client ID and Client Secret${NC}"
echo ""

# Wait for user to complete the steps
echo -e "${BLUE}⏳ Please complete the above steps in your browser...${NC}"
echo -e "${YELLOW}Press Enter when you have the Client ID and Client Secret${NC}"
read -r ""

# Get credentials from user
echo -e "${YELLOW}📝 Enter your Google OAuth credentials:${NC}"
echo ""

read -p "Client ID: " CLIENT_ID
read -p "Client Secret: " CLIENT_SECRET

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo -e "${RED}❌ Both Client ID and Client Secret are required${NC}"
    exit 1
fi

# Update the secrets file
SECRETS_FILE="/Users/pranavsinghpundir/Downloads/abcde/deployment/helm/charts/onyx/values-gcp-secrets.yaml"

if [ ! -f "$SECRETS_FILE" ]; then
    echo -e "${RED}❌ Secrets file not found: $SECRETS_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}💾 Updating secrets file...${NC}"

# Create backup
cp "$SECRETS_FILE" "$SECRETS_FILE.backup"

# Update the OAuth credentials in the secrets file
sed -i '' "s/TODO:_SET_GOOGLE_OAUTH_CLIENT_ID/$CLIENT_ID/g" "$SECRETS_FILE"
sed -i '' "s/TODO:SET_GOOGLE_OAUTH_CLIENT_SECRET/$CLIENT_SECRET/g" "$SECRETS_FILE"

echo -e "${GREEN}✅ OAuth credentials updated in secrets file${NC}"
echo -e "${YELLOW}📋 Backup created: $SECRETS_FILE.backup${NC}"

# Verify the update
echo -e "${YELLOW}🔍 Verifying the update...${NC}"
if grep -q "$CLIENT_ID" "$SECRETS_FILE" && grep -q "$CLIENT_SECRET" "$SECRETS_FILE"; then
    echo -e "${GREEN}✅ OAuth credentials successfully saved${NC}"
else
    echo -e "${RED}❌ Failed to update OAuth credentials${NC}"
    echo -e "${YELLOW}🔄 Restoring from backup...${NC}"
    mv "$SECRETS_FILE.backup" "$SECRETS_FILE"
    exit 1
fi

# Test the OAuth configuration (basic validation)
echo -e "${YELLOW}🧪 Testing OAuth configuration...${NC}"

# Basic validation of Client ID format (should look like a Google OAuth client ID)
if [[ $CLIENT_ID =~ ^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$ ]]; then
    echo -e "${GREEN}✅ Client ID format is valid${NC}"
else
    echo -e "${YELLOW}⚠️  Client ID format might be incorrect, but continuing anyway${NC}"
fi

# Validate Client Secret format (should be a reasonably long string)
if [ ${#CLIENT_SECRET} -ge 16 ]; then
    echo -e "${GREEN}✅ Client Secret format is valid${NC}"
else
    echo -e "${YELLOW}⚠️  Client Secret seems too short, but continuing anyway${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Google OAuth setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo -e "${BLUE}  - Client ID: $CLIENT_ID${NC}"
echo -e "${BLUE}  - Client Secret: ***REDACTED***${NC}"
echo -e "${BLUE}  - Redirect URIs configured for: $DOMAIN${NC}"
echo ""
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo -e "${BLUE}1. Deploy the application using Helm${NC}"
echo -e "${BLUE}2. Test OAuth login at: https://$DOMAIN${NC}"
echo -e "${BLUE}3. Monitor logs for any OAuth-related issues${NC}"
echo ""

# Show a preview of the updated secrets file (excluding actual secret values)
echo -e "${YELLOW}📄 Preview of updated secrets file:${NC}"
echo ""
grep -A 10 -B 2 "googleOAuth:" "$SECRETS_FILE" | sed "s/$CLIENT_SECRET/***CLIENT_SECRET***/g"