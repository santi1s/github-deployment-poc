# Quick Start Guide

Get up and running with the GitHub Deployment POC in 5 minutes.

## Prerequisites

- GitHub account at https://github.com/santi1s
- `curl`, `jq`, and `openssl` (usually pre-installed on macOS)
- A GitHub repository to test with (or create a new one)

## 1. Create a GitHub App

1. Go to https://github.com/settings/apps
2. Click **New GitHub App**
3. Fill in the form:
   - **App name**: `github-deployment-poc` (or whatever you prefer)
   - **Homepage URL**: `https://github.com/santi1s/github-deployment-poc`
   - **Webhook URL**: Leave blank (we don't need webhooks)
   - **Webhook active**: Uncheck it

4. Under **Permissions**:
   - Deployments: **Read & Write**
   - Contents: **Read only**

5. Under **Where can this GitHub App be installed?**:
   - ✅ Only on this account

6. Click **Create GitHub App**

7. Save these values (you'll need them):
   - **App ID** (under "About" section)
   - **Installation ID** (go to "Install App" tab, click your account, look at the URL: `https://github.com/apps/github-deployment-poc/installations/INSTALLATION_ID`)

## 2. Generate a Private Key

1. In your GitHub App settings, scroll to **Private keys**
2. Click **Generate a private key**
3. A `.pem` file will download - open it and copy the entire content (including `-----BEGIN` and `-----END` lines)

## 3. Configure the POC

1. Copy the example environment file:
   ```bash
   cd /Users/sergiosantiago/projects/personal/github-deployment-poc
   cp .env.example .env
   ```

2. Edit `.env` and fill in your values:
   ```bash
   vim .env
   ```

   Replace:
   - `GITHUB_APP_ID` with your App ID
   - `GITHUB_APP_PRIVATE_KEY` with the full PEM content (keep the `-----BEGIN` and `-----END` lines)
   - `GITHUB_APP_INSTALLATION_ID` with your Installation ID
   - `REPOSITORY` with your repo name (e.g., `github-deployment-poc`)

## 4. Test the Setup

### Option A: Run the full simulation
```bash
source .env
./scripts/deploy-simulation.sh
```

This will:
- ✅ Authenticate with GitHub
- ✅ Create a deployment
- ✅ Update status to `in_progress`
- ✅ Update status to `success`

### Option B: Run step-by-step
```bash
source .env

# Step 1: Get authentication token
./scripts/github-app-auth.sh

# Step 2: Create deployment
export GIT_SHA=$(git rev-parse HEAD)
GITHUB_TOKEN="<token-from-step-1>" ./scripts/create-deployment.sh

# Step 3: Update status
GITHUB_TOKEN="<token>" DEPLOYMENT_ID="<id-from-step-2>" \
  DEPLOY_STATE="in_progress" ./scripts/update-deployment-status.sh

# Step 4: Mark as success
GITHUB_TOKEN="<token>" DEPLOYMENT_ID="<id>" \
  DEPLOY_STATE="success" ./scripts/update-deployment-status.sh
```

### Option C: Interactive example
```bash
./examples/deploy-example.sh
```

This guides you through the process interactively.

## 5. View Results on GitHub

After running a deployment:
1. Go to your repository on GitHub
2. Click the **Deployments** tab
3. You'll see your deployment with status updates

## Troubleshooting

### "GITHUB_TOKEN not set"
Make sure you ran `source .env` first.

### "Failed to get GitHub App installation access token"
Check that:
- `GITHUB_APP_ID` is correct
- `GITHUB_APP_PRIVATE_KEY` includes the `-----BEGIN` and `-----END` lines
- `GITHUB_APP_INSTALLATION_ID` is correct and the app is installed on your account

### "Failed to create GitHub deployment"
Check that:
- `REPOSITORY` is the correct repository name (without organization prefix)
- `GIT_SHA` is a valid 40-character commit SHA
- Your GitHub App has Deployments: Read & Write permission

## Next Steps

1. **Integrate with CI/CD**: Use these scripts in your GitHub Actions, GitLab CI, or other CI/CD pipeline
2. **Add more environments**: Test with different `ENVIRONMENT` values (e.g., production)
3. **Add error handling**: Wrap the scripts in your own logic for better error messages
4. **Add notifications**: Send Slack/email notifications when deployments complete

## API Documentation

Learn more about the GitHub Deployment APIs:
- [GitHub Deployments API](https://docs.github.com/en/rest/deployments/deployments)
- [GitHub Deployment Statuses API](https://docs.github.com/en/rest/deployments/statuses)
- [GitHub Apps Authentication](https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps)

## Need Help?

Review the scripts:
- `scripts/github-app-auth.sh` - GitHub App authentication
- `scripts/create-deployment.sh` - Create a deployment
- `scripts/update-deployment-status.sh` - Update deployment status
- `scripts/deploy-simulation.sh` - Full workflow simulation
- `examples/deploy-example.sh` - Interactive example

Each script has detailed comments explaining what it does.
