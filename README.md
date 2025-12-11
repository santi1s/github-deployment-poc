# GitHub Deployment API POC

This is a proof-of-concept for GitHub Deployment creation and status updates without Argo Workflows.

## Overview

This POC demonstrates:
- Creating GitHub deployments via the GitHub REST API
- Updating deployment status (in_progress, success, failure)
- GitHub App authentication for API calls
- Local simulation of CI/CD deployment workflows

## Structure

```
.
├── .env.example           # Environment configuration template
├── scripts/
│   ├── github-app-auth.sh           # GitHub App authentication
│   ├── create-deployment.sh         # Create GitHub deployment
│   ├── update-deployment-status.sh  # Update deployment status
│   └── deploy-simulation.sh         # End-to-end deployment simulation
├── examples/
│   └── deploy-example.sh            # Example usage
└── README.md
```

## Prerequisites

- `curl` - for API calls
- `jq` - for JSON parsing
- GitHub App credentials (ID, private key, installation ID)
- Git repository with commits

## Setup

1. Copy `.env.example` to `.env` and fill in your GitHub App credentials:
   ```bash
   cp .env.example .env
   ```

2. Create a GitHub App (if you don't have one):
   - Go to GitHub Settings → Developer settings → GitHub Apps → New GitHub App
   - Set the following permissions:
     - Deployments: Read & Write
     - Contents: Read
   - Generate a private key and note your App ID and Installation ID

3. Source the environment file:
   ```bash
   source .env
   ```

## Usage

### 1. Authenticate with GitHub (get access token)
```bash
./scripts/github-app-auth.sh
```

### 2. Create a deployment
```bash
GITHUB_TOKEN="your-token" \
REPOSITORY="your-repo-name" \
GIT_SHA="abc123def456..." \
ENVIRONMENT="staging" \
./scripts/create-deployment.sh
```

### 3. Update deployment status
```bash
GITHUB_TOKEN="your-token" \
REPOSITORY="your-repo-name" \
DEPLOYMENT_ID="12345" \
DEPLOY_STATE="in_progress" \
./scripts/update-deployment-status.sh
```

### 4. Full deployment simulation
```bash
./examples/deploy-example.sh
```

## Environment Variables

- `GITHUB_APP_ID` - GitHub App ID
- `GITHUB_APP_PRIVATE_KEY` - GitHub App private key (full PEM content)
- `GITHUB_APP_INSTALLATION_ID` - Installation ID for your account/org
- `GITHUB_TOKEN` - GitHub API access token (generated from app auth)
- `REPOSITORY` - Repository name (without org prefix)
- `GIT_SHA` - Commit SHA to deploy
- `ENVIRONMENT` - Deployment environment (staging, production, etc.)
- `DEPLOYMENT_ID` - Deployment ID (for status updates)
- `DEPLOY_STATE` - Deployment state (in_progress, success, failure)
- `LOG_URL` - URL to deployment logs (optional)

## Testing

To test locally:

1. Push this repo to GitHub under your account
2. Create a GitHub App and authorize it for your repository
3. Configure `.env` with your credentials
4. Run the example script:
   ```bash
   source .env
   ./examples/deploy-example.sh
   ```

## API References

- [GitHub Deployments API](https://docs.github.com/en/rest/deployments/deployments)
- [GitHub Deployment Statuses API](https://docs.github.com/en/rest/deployments/statuses)
- [GitHub App Authentication](https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps)
