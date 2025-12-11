#!/bin/bash

# GitHub App Authentication Script
# Generates a GitHub App installation access token for API calls
# Usage: ./scripts/github-app-auth.sh

set -e

if [ -z "$GITHUB_APP_ID" ] || [ -z "$GITHUB_APP_PRIVATE_KEY" ] || [ -z "$GITHUB_APP_INSTALLATION_ID" ]; then
  echo "ERROR: Missing required environment variables"
  echo "  - GITHUB_APP_ID"
  echo "  - GITHUB_APP_PRIVATE_KEY"
  echo "  - GITHUB_APP_INSTALLATION_ID"
  echo ""
  echo "Load your .env file first:"
  echo "  source .env"
  exit 1
fi

echo "🔐 Generating GitHub App JWT..."

# Save private key to temp file
TEMP_KEY=$(mktemp)
trap "rm -f $TEMP_KEY" EXIT
echo "$GITHUB_APP_PRIVATE_KEY" > "$TEMP_KEY"

# Create JWT header and payload
NOW=$(date +%s)
EXPIRY=$((NOW + 600))  # Token expires in 10 minutes

HEADER='{"alg":"RS256","typ":"JWT"}'
PAYLOAD=$(cat <<EOF
{
  "iat": $NOW,
  "exp": $EXPIRY,
  "iss": "$GITHUB_APP_ID"
}
EOF
)

# Base64url encode
HEADER_B64=$(echo -n "$HEADER" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
PAYLOAD_B64=$(echo -n "$PAYLOAD" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

# Create signature
SIGNATURE=$(echo -n "${HEADER_B64}.${PAYLOAD_B64}" | openssl dgst -sha256 -sign "$TEMP_KEY" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

JWT="${HEADER_B64}.${PAYLOAD_B64}.${SIGNATURE}"

echo "✅ JWT generated (valid for 10 minutes)"
echo ""
echo "🔑 Exchanging JWT for installation access token..."

# Get installation access token
TOKEN_RESPONSE=$(curl -sS -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/app/installations/$GITHUB_APP_INSTALLATION_ID/access_tokens)

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token // empty')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ ERROR: Failed to get GitHub App installation access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "✅ Successfully obtained GitHub App access token"
echo ""
echo "📋 Token Details:"
echo "$TOKEN_RESPONSE" | jq '.'
echo ""
echo "💾 To use this token in other scripts, run:"
echo "  export GITHUB_TOKEN='$ACCESS_TOKEN'"
echo ""
echo "Token: $ACCESS_TOKEN"
