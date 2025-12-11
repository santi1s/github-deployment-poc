# GitHub Deployment API POC

This is a proof-of-concept for GitHub Deployment creation and status updates without Argo Workflows.

## 🔑 Key Discovery

**To display deployments on GitHub commit pages, you need TWO separate APIs:**

1. **Deployments API** - Creates deployment records
2. **Statuses API** - Creates commit status badges ← This was the missing piece!

This POC now includes both, so deployments **fully display on commit pages**.

See: [SOLUTION_SUMMARY.md](SOLUTION_SUMMARY.md) for details.

## Overview

This POC demonstrates:
- Creating GitHub deployments via the GitHub REST API ✅
- Updating deployment status (in_progress, success, failure) ✅
- Creating commit status badges (THE KEY FIX!) ✅
- GitHub App authentication for API calls ✅
- Local simulation of CI/CD deployment workflows ✅
- Full integration: deployments visible on commits AND in API ✅

## Structure

```
.
├── .env.example                      # Environment configuration template
├── scripts/
│   ├── github-app-auth.sh            # GitHub App authentication
│   ├── create-deployment.sh          # Create GitHub deployment
│   ├── update-deployment-status.sh   # Update deployment status
│   ├── create-commit-status.sh       # Create commit status badges ⭐ NEW!
│   ├── deploy-simulation.sh          # End-to-end deployment simulation
│   ├── list-deployments.sh           # List all deployments
│   └── get-deployment-status.sh      # Get deployment status history
├── Documentation/
│   ├── README.md                     # This file
│   ├── SOLUTION_SUMMARY.md           # Overview of the fix
│   ├── QUICK_REFERENCE.md            # Quick lookup guide
│   ├── COMMIT_STATUS_EXPLANATION.md  # Technical deep-dive
│   ├── DEPLOYMENTS_EXPLAINED.md      # Deployment concepts
│   ├── PERMISSIONS_FIX.md            # Permission requirements
│   ├── GITHUB_PERMISSIONS_ANALYSIS.md # Why permissions matter
│   ├── ARCHITECTURE.md               # System design
│   └── TESTING.md                    # Test scenarios
└── .gitignore
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
     - Statuses: Read & Write ⭐ (REQUIRED for commit page display)
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
