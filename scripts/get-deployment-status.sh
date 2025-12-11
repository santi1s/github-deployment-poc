#!/bin/bash

# Get detailed status for a specific deployment
# Usage:
#   GITHUB_TOKEN="token" REPOSITORY="repo" DEPLOYMENT_ID="123" ./scripts/get-deployment-status.sh
#   Optional: GITHUB_ORG="santi1s" (default: santi1s)

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

if [ -z "$DEPLOYMENT_ID" ]; then
  echo "❌ ERROR: DEPLOYMENT_ID not set"
  exit 1
fi

GITHUB_ORG="${GITHUB_ORG:-santi1s}"

echo "📋 Fetching status for deployment $DEPLOYMENT_ID..."
echo ""

RESPONSE=$(curl -sS -X GET \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_ORG/$REPOSITORY/deployments/$DEPLOYMENT_ID/statuses")

echo "📊 Deployment Status History:"
echo ""
echo "$RESPONSE" | jq -r '.[] |
  "State: \(.state)
  Description: \(.description // "N/A")
  Created: \(.created_at)
  Log URL: \(.log_url // "N/A")
  ---"'

echo ""
echo "📈 Summary:"
LATEST_STATE=$(echo "$RESPONSE" | jq -r '.[0].state // "unknown"')
echo "Latest State: $LATEST_STATE"
