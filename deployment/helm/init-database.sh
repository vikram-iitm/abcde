#!/bin/bash

# Database initialization script for Onyx on GCP
# This script sets up the database schema and users

set -e

# Configuration
DB_HOST="10.72.0.3"
DB_PORT="5432"
DB_NAME="onyx"
DB_ADMIN_USER="postgres"
DB_ADMIN_PASSWORD="Dtzaq5gLMmWYAmnjZLfd+Js4R+mhfKmWOHKlB1mrDog="
DB_READONLY_USER="db_readonly_user"
DB_READONLY_PASSWORD="juaAC6Rk0lZNM+TZqhZR69BaZYVcGJfVzTUreXIQM98="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🗄️  Initializing Onyx database...${NC}"

# Wait for database to be available
echo -e "${YELLOW}⏳ Waiting for database to be available...${NC}"
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME"; do
    echo -e "${YELLOW}Database is unavailable - sleeping${NC}"
    sleep 2
done

echo -e "${GREEN}✅ Database is available${NC}"

# Create readonly user if it doesn't exist
echo -e "${YELLOW}👤 Creating readonly user...${NC}"
PGPASSWORD="$DB_ADMIN_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME" -c "
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE rolname = '$DB_READONLY_USER'
    ) THEN
        CREATE ROLE $DB_READONLY_USER WITH LOGIN PASSWORD '$DB_READONLY_PASSWORD';
    END IF;
END
\$\$;
"

# Grant readonly permissions
echo -e "${YELLOW}🔐 Setting up permissions...${NC}"
PGPASSWORD="$DB_ADMIN_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME" -c "
-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO $DB_READONLY_USER;

-- Grant select on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO $DB_READONLY_USER;

-- Grant select on all sequences
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $DB_READONLY_USER;

-- Set default permissions for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $DB_READONLY_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO $DB_READONLY_USER;
"

echo -e "${GREEN}✅ Database permissions configured${NC}"

# Check if Alembic tables exist (to determine if we need to run migrations)
echo -e "${YELLOW}🔍 Checking for existing migrations...${NC}"
ALEMBIC_TABLE_EXISTS=$(PGPASSWORD="$DB_ADMIN_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME" -t -c "
SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'alembic_version'
);
")

if [ "$ALEMBIC_TABLE_EXISTS" = "t" ]; then
    echo -e "${YELLOW}📊 Alembic version table exists, checking current version...${NC}"
    CURRENT_VERSION=$(PGPASSWORD="$DB_ADMIN_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME" -t -c "SELECT version_num FROM alembic_version LIMIT 1;")
    echo -e "${GREEN}📈 Current database version: $CURRENT_VERSION${NC}"
else
    echo -e "${YELLOW}🆕 No existing migrations found, database is fresh${NC}"
fi

# Test database connectivity
echo -e "${YELLOW}🔌 Testing database connectivity...${NC}"
PGPASSWORD="$DB_ADMIN_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_ADMIN_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null
echo -e "${GREEN}✅ Database connectivity test successful${NC}"

# Test readonly user
echo -e "${YELLOW}🔌 Testing readonly user...${NC}"
PGPASSWORD="$DB_READONLY_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_READONLY_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null
echo -e "${GREEN}✅ Readonly user test successful${NC}"

echo -e "${GREEN}🎉 Database initialization complete!${NC}"
echo -e "${YELLOW}📝 Database details:${NC}"
echo -e "${YELLOW}  Host: $DB_HOST:$DB_PORT${NC}"
echo -e "${YELLOW}  Database: $DB_NAME${NC}"
echo -e "${YELLOW}  Admin User: $DB_ADMIN_USER${NC}"
echo -e "${YELLOW}  Readonly User: $DB_READONLY_USER${NC}"

echo -e "${YELLOW}🚀 Next steps:${NC}"
echo -e "${YELLOW}1. Run database migrations using Alembic${NC}"
echo -e "${YELLOW}2. Deploy the application using Helm${NC}"