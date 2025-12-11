#!/bin/bash

# Example: Manual Deployment Workflow
# This demonstrates how to use the deployment scripts step-by-step
# You can adapt this for your own CI/CD pipeline

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "📚 Example: Manual Deployment Workflow"
echo ""
echo "This script shows how to manually trigger a deployment"
echo "Step 1: Make sure you have .env configured"
echo "Step 2: Make sure you have committed code to deploy"
echo ""

# Load environment
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "❌ ERROR: .env file not found"
  echo ""
  echo "Create and configure .env first:"
  echo "  cp $SCRIPT_DIR/.env.example $SCRIPT_DIR/.env"
  echo "  vim $SCRIPT_DIR/.env"
  exit 1
fi

source "$SCRIPT_DIR/.env"

# Step 1: Get commit SHA
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Select commit to deploy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Recent commits in this repository:"
  echo ""
  git log --oneline -5
  echo ""
  read -p "Enter commit SHA (or press Enter for HEAD): " COMMIT_CHOICE

  if [ -z "$COMMIT_CHOICE" ]; then
    GIT_SHA=$(git rev-parse HEAD)
  else
    GIT_SHA="$COMMIT_CHOICE"
  fi
else
  echo "Not in a git repository."
  read -p "Enter commit SHA to deploy: " GIT_SHA
fi

echo "Selected commit: $GIT_SHA"
echo ""

# Step 2: Get auth token
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Authenticate with GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TEMP_AUTH=$(mktemp)
if ! GITHUB_APP_ID="$GITHUB_APP_ID" \
     GITHUB_APP_PRIVATE_KEY="$GITHUB_APP_PRIVATE_KEY" \
     GITHUB_APP_INSTALLATION_ID="$GITHUB_APP_INSTALLATION_ID" \
     bash "$SCRIPT_DIR/scripts/github-app-auth.sh" > "$TEMP_AUTH" 2>&1; then
  echo "❌ Authentication failed"
  cat "$TEMP_AUTH"
  rm -f "$TEMP_AUTH"
  exit 1
fi

GITHUB_TOKEN=$(grep "^Token: " "$TEMP_AUTH" | cut -d' ' -f2)
rm -f "$TEMP_AUTH"

echo "✅ Authenticated successfully"
echo ""

# Step 3: Create deployment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Create GitHub deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TEMP_DEPLOY=$(mktemp)
if ! GITHUB_TOKEN="$GITHUB_TOKEN" \
     REPOSITORY="$REPOSITORY" \
     GIT_SHA="$GIT_SHA" \
     ENVIRONMENT="${ENVIRONMENT:-staging}" \
     GITHUB_ORG="$GITHUB_ORG" \
     bash "$SCRIPT_DIR/scripts/create-deployment.sh" > "$TEMP_DEPLOY" 2>&1; then
  echo "❌ Failed to create deployment"
  cat "$TEMP_DEPLOY"
  rm -f "$TEMP_DEPLOY"
  exit 1
fi

DEPLOYMENT_ID=$(grep "^💾 Deployment ID: " "$TEMP_DEPLOY" | cut -d' ' -f4)
rm -f "$TEMP_DEPLOY"

echo "✅ Deployment created with ID: $DEPLOYMENT_ID"
echo ""

# Step 4: Update status to in_progress
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Start deployment (in_progress)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! GITHUB_TOKEN="$GITHUB_TOKEN" \
     REPOSITORY="$REPOSITORY" \
     DEPLOYMENT_ID="$DEPLOYMENT_ID" \
     DEPLOY_STATE="in_progress" \
     ENVIRONMENT="${ENVIRONMENT:-staging}" \
     GITHUB_ORG="$GITHUB_ORG" \
     bash "$SCRIPT_DIR/scripts/update-deployment-status.sh" > /dev/null 2>&1; then
  echo "❌ Failed to update status"
  exit 1
fi

echo "✅ Deployment status: in_progress"
echo ""

# Step 5: Simulate deployment work
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Simulating deployment (10 seconds)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in {1..10}; do
  echo "⏳ Deploying... $i/10"
  sleep 1
done

echo ""

# Step 6: Update status to success
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 6: Mark deployment as success"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LOG_URL="https://github.com/$GITHUB_ORG/$REPOSITORY/deployments/$DEPLOYMENT_ID"

if ! GITHUB_TOKEN="$GITHUB_TOKEN" \
     REPOSITORY="$REPOSITORY" \
     DEPLOYMENT_ID="$DEPLOYMENT_ID" \
     DEPLOY_STATE="success" \
     ENVIRONMENT="${ENVIRONMENT:-staging}" \
     GITHUB_ORG="$GITHUB_ORG" \
     LOG_URL="$LOG_URL" \
     bash "$SCRIPT_DIR/scripts/update-deployment-status.sh" > /dev/null 2>&1; then
  echo "❌ Failed to mark deployment as success"
  exit 1
fi

echo "✅ Deployment status: success"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment workflow completed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "   Repository: $GITHUB_ORG/$REPOSITORY"
echo "   Commit: $GIT_SHA"
echo "   Environment: ${ENVIRONMENT:-staging}"
echo "   Deployment ID: $DEPLOYMENT_ID"
echo ""
echo "🔗 View on GitHub:"
echo "   https://github.com/$GITHUB_ORG/$REPOSITORY/deployments"
echo ""
