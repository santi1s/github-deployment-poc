#!/bin/bash

# Create a commit status (badge) on a commit
# This is what makes deployments appear on commit pages
# Usage:
#   GITHUB_TOKEN="token" REPOSITORY="repo" GIT_SHA="abc123" STATE="success" ./scripts/create-commit-status.sh
#   Optional: ENVIRONMENT="staging", DESCRIPTION="message", DEPLOYMENT_URL="url"

set -e

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ ERROR: GITHUB_TOKEN not set"
  exit 1
fi

if [ -z "$REPOSITORY" ]; then
  echo "❌ ERROR: REPOSITORY not set"
  exit 1
fi

if [ -z "$GIT_SHA" ]; then
  echo "❌ ERROR: GIT_SHA not set"
  exit 1
fi

if [ -z "$STATE" ]; then
  echo "❌ ERROR: STATE not set (must be: pending, success, failure, error)"
  exit 1
fi

# Optional variables with defaults
GITHUB_ORG="${GITHUB_ORG:-santi1s}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
DESCRIPTION="${DESCRIPTION:-Deployment to $ENVIRONMENT}"
DEPLOYMENT_URL="${DEPLOYMENT_URL:-https://github.com/$GITHUB_ORG/$REPOSITORY/deployments}"
CONTEXT="${CONTEXT:-deploy/$ENVIRONMENT}"

# Validate state
case "$STATE" in
  pending|success|failure|error)
    ;;
  *)
    echo "❌ ERROR: Invalid STATE: $STATE"
    echo "   Must be one of: pending, success, failure, error"
    exit 1
    ;;
esac

echo "📍 Creating commit status..."
echo "   Commit: $GIT_SHA"
echo "   State: $STATE"
echo "   Context: $CONTEXT"
echo ""

# Create the status
RESPONSE=$(curl -sS -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{
    \"state\": \"$STATE\",
    \"description\": \"$DESCRIPTION\",
    \"context\": \"$CONTEXT\",
    \"target_url\": \"$DEPLOYMENT_URL\"
  }" \
  "https://api.github.com/repos/$GITHUB_ORG/$REPOSITORY/statuses/$GIT_SHA")

# Check for errors
ERROR=$(echo "$RESPONSE" | jq -r '.errors // empty' 2>/dev/null)
if [ -n "$ERROR" ]; then
  echo "❌ ERROR: Failed to create commit status"
  echo "$RESPONSE" | jq '.'
  exit 1
fi

# Extract status ID
STATUS_URL=$(echo "$RESPONSE" | jq -r '.url // empty' 2>/dev/null)
if [ -z "$STATUS_URL" ]; then
  echo "❌ ERROR: No status URL returned"
  echo "$RESPONSE" | jq '.'
  exit 1
fi

echo "✅ Commit status created successfully"
echo "   Status URL: $STATUS_URL"
echo ""
echo "💾 Status Details:"
echo "$RESPONSE" | jq '{state, context, description, target_url, created_at, updated_at}'
