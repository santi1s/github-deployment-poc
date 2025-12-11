#!/bin/bash

# Full Deployment Simulation Script
# Simulates a complete deployment workflow: auth → create → in_progress → success
# Usage: ./scripts/deploy-simulation.sh

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PROJECT_DIR/.env" ]; then
  echo -e "${RED}❌ ERROR: .env file not found${NC}"
  echo ""
  echo "Create one from the template:"
  echo "  cp $PROJECT_DIR/.env.example $PROJECT_DIR/.env"
  echo ""
  echo "Then edit it with your GitHub App credentials:"
  echo "  vim $PROJECT_DIR/.env"
  exit 1
fi

# Source environment
source "$PROJECT_DIR/.env"

# Validate required variables
for var in GITHUB_APP_ID GITHUB_APP_PRIVATE_KEY GITHUB_APP_INSTALLATION_ID REPOSITORY GITHUB_ORG; do
  if [ -z "${!var}" ]; then
    echo -e "${RED}❌ ERROR: $var not set in .env${NC}"
    exit 1
  fi
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   GitHub Deployment Simulation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Get current commit SHA
echo -e "${YELLOW}Step 1/4: Getting latest commit SHA...${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
  GIT_SHA=$(git rev-parse HEAD)
  echo -e "${GREEN}✅ Found commit: $GIT_SHA${NC}"
else
  echo -e "${YELLOW}⚠️  Not in a git repository, generating fake SHA${NC}"
  GIT_SHA=$(openssl rand -hex 20)
  echo -e "${GREEN}✅ Using SHA: $GIT_SHA${NC}"
fi
echo ""

# Step 2: Authenticate with GitHub
echo -e "${YELLOW}Step 2/4: Authenticating with GitHub...${NC}"
TEMP_AUTH=$(mktemp)
trap "rm -f $TEMP_AUTH" EXIT

if bash "$SCRIPT_DIR/github-app-auth.sh" > "$TEMP_AUTH" 2>&1; then
  GITHUB_TOKEN=$(grep "^Token: " "$TEMP_AUTH" | cut -d' ' -f2)
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Failed to extract token${NC}"
    cat "$TEMP_AUTH"
    exit 1
  fi
  echo -e "${GREEN}✅ Authentication successful${NC}"
else
  echo -e "${RED}❌ Authentication failed${NC}"
  cat "$TEMP_AUTH"
  exit 1
fi
echo ""

# Step 3: Create deployment
echo -e "${YELLOW}Step 3/4: Creating GitHub deployment...${NC}"
ENVIRONMENT="${ENVIRONMENT:-staging}"

TEMP_CREATE=$(mktemp)
trap "rm -f $TEMP_CREATE $TEMP_AUTH" EXIT

if GITHUB_TOKEN="$GITHUB_TOKEN" REPOSITORY="$REPOSITORY" GIT_SHA="$GIT_SHA" \
   ENVIRONMENT="$ENVIRONMENT" GITHUB_ORG="$GITHUB_ORG" \
   bash "$SCRIPT_DIR/create-deployment.sh" > "$TEMP_CREATE" 2>&1; then
  DEPLOYMENT_ID=$(grep "^💾 Deployment ID: " "$TEMP_CREATE" | cut -d' ' -f4)
  if [ -z "$DEPLOYMENT_ID" ] || [ "$DEPLOYMENT_ID" = "null" ]; then
    echo -e "${RED}❌ Failed to extract deployment ID${NC}"
    cat "$TEMP_CREATE"
    exit 1
  fi
  echo -e "${GREEN}✅ Deployment created with ID: $DEPLOYMENT_ID${NC}"
else
  echo -e "${RED}❌ Failed to create deployment${NC}"
  cat "$TEMP_CREATE"
  exit 1
fi
echo ""

# Step 4: Update status progression
echo -e "${YELLOW}Step 4/4: Simulating deployment progress...${NC}"
echo ""

# in_progress
echo -e "  ${BLUE}→${NC} Updating status to: ${YELLOW}in_progress${NC}"
if GITHUB_TOKEN="$GITHUB_TOKEN" REPOSITORY="$REPOSITORY" DEPLOYMENT_ID="$DEPLOYMENT_ID" \
   DEPLOY_STATE="in_progress" ENVIRONMENT="$ENVIRONMENT" GITHUB_ORG="$GITHUB_ORG" \
   bash "$SCRIPT_DIR/update-deployment-status.sh" > /dev/null 2>&1; then
  echo -e "    ${GREEN}✅ Status updated${NC}"
  sleep 2
else
  echo -e "    ${RED}❌ Failed to update status${NC}"
  exit 1
fi

# Simulate deployment work
echo -e "  ${BLUE}→${NC} Simulating deployment work..."
for i in {1..3}; do
  echo -e "    ⏳ Working... $i/3"
  sleep 1
done

# success
echo -e "  ${BLUE}→${NC} Updating status to: ${GREEN}success${NC}"
LOG_URL="https://github.com/$GITHUB_ORG/$REPOSITORY/deployments/$DEPLOYMENT_ID"

if GITHUB_TOKEN="$GITHUB_TOKEN" REPOSITORY="$REPOSITORY" DEPLOYMENT_ID="$DEPLOYMENT_ID" \
   DEPLOY_STATE="success" ENVIRONMENT="$ENVIRONMENT" GITHUB_ORG="$GITHUB_ORG" \
   LOG_URL="$LOG_URL" \
   bash "$SCRIPT_DIR/update-deployment-status.sh" > /dev/null 2>&1; then
  echo -e "    ${GREEN}✅ Deployment completed successfully${NC}"
else
  echo -e "    ${RED}❌ Failed to update final status${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Deployment simulation completed successfully!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "📊 Deployment Summary:"
echo "   Repository: $GITHUB_ORG/$REPOSITORY"
echo "   Commit: $GIT_SHA"
echo "   Environment: $ENVIRONMENT"
echo "   Deployment ID: $DEPLOYMENT_ID"
echo ""
echo "🔗 View deployment on GitHub:"
echo "   https://github.com/$GITHUB_ORG/$REPOSITORY/deployments"
echo ""
