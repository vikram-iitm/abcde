#!/bin/bash

# Database migration script for Onyx on GCP
# This script runs Alembic migrations to set up the database schema

set -e

# Configuration
DB_HOST="10.72.0.3"
DB_PORT="5432"
DB_NAME="onyx"
DB_USER="postgres"
DB_PASSWORD="Dtzaq5gLMmWYAmnjZLfd+Js4R+mhfKmWOHKlB1mrDog="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Running Onyx database migrations...${NC}"

# Set environment variables for migrations
export POSTGRES_HOST="$DB_HOST"
export POSTGRES_PORT="$DB_PORT"
export POSTGRES_DB="$DB_NAME"
export POSTGRES_USER="$DB_USER"
export POSTGRES_PASSWORD="$DB_PASSWORD"
export POSTGRES_SSL_MODE="require"

# Check if alembic is available
if ! command -v alembic &> /dev/null; then
    echo -e "${RED}❌ Alembic is not installed. Please install it first.${NC}"
    echo -e "${YELLOW}💡 You can install it with: pip install alembic${NC}"
    exit 1
fi

# Navigate to the backend directory
if [ ! -d "backend" ]; then
    echo -e "${RED}❌ Backend directory not found. Please run this script from the project root.${NC}"
    exit 1
fi

cd backend

# Check if alembic.ini exists
if [ ! -f "alembic.ini" ]; then
    echo -e "${RED}❌ alembic.ini not found in backend directory.${NC}"
    echo -e "${YELLOW}💡 Please ensure you're in the correct project directory.${NC}"
    exit 1
fi

# Test database connection
echo -e "${YELLOW}🔌 Testing database connection...${NC}"
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null
echo -e "${GREEN}✅ Database connection successful${NC}"

# Check current migration status
echo -e "${YELLOW}📊 Checking current migration status...${NC}"
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'alembic_version');" | grep -q "t"; then
    CURRENT_VERSION=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT version_num FROM alembic_version;")
    echo -e "${GREEN}📈 Current database version: $CURRENT_VERSION${NC}"
else
    echo -e "${YELLOW}🆕 Database appears to be fresh, no migrations found${NC}"
fi

# Run Alembic upgrade
echo -e "${YELLOW}⬆️  Running database migrations...${NC}"
if alembic upgrade head; then
    echo -e "${GREEN}✅ Database migrations completed successfully${NC}"
else
    echo -e "${RED}❌ Database migrations failed${NC}"
    exit 1
fi

# Verify the migration
echo -e "${YELLOW}✅ Verifying migration...${NC}"
NEW_VERSION=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT version_num FROM alembic_version;")
echo -e "${GREEN}📈 Database is now at version: $NEW_VERSION${NC}"

# Check if key tables were created
echo -e "${YELLOW}🔍 Verifying key tables...${NC}"
TABLES=("user" "tenant" "document" "search_settings")
for table in "${TABLES[@]}"; do
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '$table');" | grep -q "t"; then
        echo -e "${GREEN}✅ Table '$table' exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Table '$table' not found (this might be expected)${NC}"
    fi
done

echo -e "${GREEN}🎉 Database migrations complete!${NC}"

# Create initial admin user if needed
echo -e "${YELLOW}👤 Checking if admin user needs to be created...${NC}"
ADMIN_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS (SELECT 1 FROM \"user\" WHERE email = 'admin@ramdev.live');")
if [ "$ADMIN_EXISTS" = "f" ]; then
    echo -e "${YELLOW}👤 Admin user not found, you'll need to create one after deployment${NC}"
    echo -e "${YELLOW}💡 Use the application's user creation interface or run the appropriate script${NC}"
else
    echo -e "${GREEN}✅ Admin user already exists${NC}"
fi

cd ..

echo -e "${GREEN}🚀 Migration process complete!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}1. Deploy the application using Helm${NC}"
echo -e "${YELLOW}2. Set up Google OAuth credentials${NC}"
echo -e "${YELLOW}3. Create initial admin user if needed${NC}"