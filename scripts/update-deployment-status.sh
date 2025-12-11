#!/bin/bash

# Update GitHub Deployment Status Script
# Usage:
#   GITHUB_TOKEN="token" REPOSITORY="repo" DEPLOYMENT_ID="123" \
#   DEPLOY_STATE="in_progress" ./scripts/update-deployment-status.sh
#   Optional: LOG_URL="https://..." (default: empty)
#   Optional: ENVIRONMENT="staging" (default: staging)
#   Optional: DESCRIPTION="Custom message" (default: auto-generated)

set -e

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ ERROR: GITHUB_TOKEN not set"
  echo "Get a token first:"
  echo "  ./scripts/github-app-auth.sh"
  exit 1
fi

if [ -z "$REPOSITORY" ]; then
  echo "❌ ERROR: REPOSITORY not set"
  echo "Example:"
  echo "  export REPOSITORY='my-app'"
  exit 1
fi

if [ -z "$DEPLOYMENT_ID" ]; then
  echo "❌ ERROR: DEPLOYMENT_ID not set"
  echo "Create a deployment first:"
  echo "  ./scripts/create-deployment.sh"
  exit 1
fi

if [ -z "$DEPLOY_STATE" ]; then
  echo "❌ ERROR: DEPLOY_STATE not set"
  echo "Valid states: in_progress, success, failure, pending"
  exit 1
fi

# Set defaults
ENVIRONMENT="${ENVIRONMENT:-staging}"
LOG_URL="${LOG_URL:-}"
GITHUB_ORG="${GITHUB_ORG:-santi1s}"

# Auto-generate description based on state
case "$DEPLOY_STATE" in
  in_progress)
    DESCRIPTION="${DESCRIPTION:-Deployment in progress...}"
    ;;
  success)
    DESCRIPTION="${DESCRIPTION:-Deployment completed successfully}"
    ;;
  failure)
    DESCRIPTION="${DESCRIPTION:-Deployment failed}"
    ;;
  pending)
    DESCRIPTION="${DESCRIPTION:-Deployment pending}"
    ;;
  *)
    DESCRIPTION="${DESCRIPTION:-Deployment status: $DEPLOY_STATE}"
    ;;
esac

echo "📤 Updating GitHub deployment status..."
echo "   Organization: $GITHUB_ORG"
echo "   Repository: $REPOSITORY"
echo "   Deployment ID: $DEPLOYMENT_ID"
echo "   State: $DEPLOY_STATE"
echo "   Environment: $ENVIRONMENT"
echo "   Description: $DESCRIPTION"
if [ -n "$LOG_URL" ]; then
  echo "   Log URL: $LOG_URL"
fi
echo ""

# Build request body
REQUEST_BODY="{
  \"state\": \"$DEPLOY_STATE\",
  \"environment\": \"$ENVIRONMENT\",
  \"description\": \"$DESCRIPTION\""

if [ -n "$LOG_URL" ]; then
  REQUEST_BODY="$REQUEST_BODY,
  \"log_url\": \"$LOG_URL\""
fi

REQUEST_BODY="$REQUEST_BODY
}"

RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_ORG/$REPOSITORY/deployments/$DEPLOYMENT_ID/statuses" \
  -d "$REQUEST_BODY")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
# Extract response body (all but last line)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "❌ ERROR: Failed to update deployment status (HTTP $HTTP_CODE)"
  echo ""
  echo "Response:"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  exit 1
fi

echo "✅ Successfully updated deployment status to: $DEPLOY_STATE"
echo ""
echo "📋 Status Details:"
echo "$BODY" | jq '.'
