#!/bin/bash

# Create GitHub Deployment Script
# Usage:
#   GITHUB_TOKEN="token" REPOSITORY="repo" GIT_SHA="abc123..." ./scripts/create-deployment.sh
#   Optional: ENVIRONMENT="staging" (default: staging)
#   Optional: IS_PRODUCTION=true (default: false)

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

if [ -z "$GIT_SHA" ]; then
  echo "❌ ERROR: GIT_SHA not set"
  echo "Example:"
  echo "  export GIT_SHA='abc123def456...'"
  exit 1
fi

# Set defaults
ENVIRONMENT="${ENVIRONMENT:-staging}"
IS_PRODUCTION="${IS_PRODUCTION:-false}"
GITHUB_ORG="${GITHUB_ORG:-santi1s}"

echo "📦 Creating GitHub deployment..."
echo "   Organization: $GITHUB_ORG"
echo "   Repository: $REPOSITORY"
echo "   Commit: $GIT_SHA"
echo "   Environment: $ENVIRONMENT"
echo "   Production: $IS_PRODUCTION"
echo ""

RESPONSE=$(curl -sS -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_ORG/$REPOSITORY/deployments" \
  -d "{
    \"ref\": \"$GIT_SHA\",
    \"environment\": \"$ENVIRONMENT\",
    \"auto_merge\": false,
    \"required_contexts\": [],
    \"transient_environment\": false,
    \"production_environment\": $IS_PRODUCTION
  }")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
# Extract response body (all but last line)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "❌ ERROR: Failed to create GitHub deployment (HTTP $HTTP_CODE)"
  echo ""
  echo "Response:"
  echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
  exit 1
fi

DEPLOYMENT_ID=$(echo "$BODY" | jq -r '.id // empty')

if [ -z "$DEPLOYMENT_ID" ] || [ "$DEPLOYMENT_ID" = "null" ]; then
  echo "❌ ERROR: Failed to extract deployment ID from response"
  echo ""
  echo "Response:"
  echo "$BODY" | jq '.'
  exit 1
fi

echo "✅ Successfully created GitHub deployment"
echo ""
echo "📋 Deployment Details:"
echo "$BODY" | jq '.'
echo ""
echo "💾 Deployment ID: $DEPLOYMENT_ID"
echo ""
echo "To use this deployment ID in status updates, run:"
echo "  export DEPLOYMENT_ID='$DEPLOYMENT_ID'"
