#!/bin/bash

# List all deployments for a repository
# Usage:
#   GITHUB_TOKEN="token" REPOSITORY="repo" ./scripts/list-deployments.sh
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

GITHUB_ORG="${GITHUB_ORG:-santi1s}"

echo "📋 Fetching deployments for $GITHUB_ORG/$REPOSITORY..."
echo ""

RESPONSE=$(curl -sS -X GET \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_ORG/$REPOSITORY/deployments")

DEPLOYMENT_COUNT=$(echo "$RESPONSE" | jq 'length')

if [ "$DEPLOYMENT_COUNT" -eq 0 ]; then
  echo "No deployments found."
  exit 0
fi

echo "Found $DEPLOYMENT_COUNT deployment(s):"
echo ""

echo "$RESPONSE" | jq -r '.[] |
  "ID: \(.id)
  Environment: \(.environment)
  Ref: \(.ref)
  Status: \(.statuses[0].state // "pending")
  Created: \(.created_at)
  ---"'

echo ""
echo "📊 Summary:"
echo "$RESPONSE" | jq -r 'group_by(.environment) |
  .[] |
  "Environment: \(.[0].environment) - \(length) deployment(s)"'
