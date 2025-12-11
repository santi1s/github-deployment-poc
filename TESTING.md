# Testing Guide

Complete testing instructions for the GitHub Deployment POC.

## Prerequisites

- GitHub account at https://github.com/santi1s
- Basic familiarity with bash scripts
- `curl`, `jq`, `openssl` (all pre-installed on macOS)

## Phase 1: GitHub App Setup (15 minutes)

### 1.1 Create GitHub App

1. Navigate to https://github.com/settings/apps
2. Click **New GitHub App**
3. Fill in the form:

| Field | Value |
|-------|-------|
| App name | `github-deployment-poc` |
| Homepage URL | `https://github.com/santi1s/github-deployment-poc` |
| Webhook URL | Leave blank |
| Webhook active | Uncheck |

4. Under "Repository permissions":
   - Set **Deployments**: Read & write
   - Set **Contents**: Read-only

5. Under "Where can this GitHub App be installed?":
   - Select **Only on this account**

6. Click **Create GitHub App**

### 1.2 Get Credentials

**App ID:**
1. Go to your app's main settings page
2. Look for "App ID" in the "About" section
3. Copy it (you'll need this for `GITHUB_APP_ID`)

**Installation ID:**
1. Click "Install App" tab
2. Click your account/organization
3. Note the URL: `https://github.com/apps/github-deployment-poc/installations/INSTALLATION_ID`
4. Copy the number after `/installations/` (you'll need this for `GITHUB_APP_INSTALLATION_ID`)

**Private Key:**
1. Scroll to "Private keys" section
2. Click "Generate a private key"
3. A `.pem` file will download
4. Open it with a text editor
5. Copy the **entire content** including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`
6. Save for `GITHUB_APP_PRIVATE_KEY`

## Phase 2: POC Configuration (5 minutes)

### 2.1 Create .env file

```bash
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
cp .env.example .env
```

### 2.2 Edit .env

```bash
vim .env
```

Fill in these values:

```bash
GITHUB_APP_ID="12345"  # Your App ID from step 1.2

# Paste the entire PEM content (keep BEGIN and END lines):
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
... (many lines) ...
-----END RSA PRIVATE KEY-----"

GITHUB_APP_INSTALLATION_ID="54321"  # Installation ID from step 1.2

REPOSITORY="github-deployment-poc"  # The repo name
GITHUB_ORG="santi1s"               # Your GitHub username
ENVIRONMENT="staging"              # Default environment
```

### 2.3 Verify configuration

```bash
source .env
echo "✅ Configuration loaded successfully"
```

You should see no errors. If you see errors:
- Check that `GITHUB_APP_PRIVATE_KEY` includes the full PEM (check for `-----BEGIN` line)
- Verify all values are quoted properly
- Don't include extra whitespace

## Phase 3: Basic Functionality Testing (10 minutes)

### 3.1 Test GitHub App Authentication

```bash
source .env
./scripts/github-app-auth.sh
```

**Expected output:**
- "Generating GitHub App JWT..."
- "JWT generated (valid for 10 minutes)"
- "Exchanging JWT for installation access token..."
- "Successfully obtained GitHub App access token"
- JSON response with token details
- Final line: "Token: <long-token-string>"

**If it fails:**
- Check error message carefully
- Verify `GITHUB_APP_ID`, `GITHUB_APP_PRIVATE_KEY`, and `GITHUB_APP_INSTALLATION_ID`
- Ensure the app is installed on your account

### 3.2 Test Deployment Creation

```bash
source .env

# Get auth token
TOKEN=$(./scripts/github-app-auth.sh 2>/dev/null | grep "^Token: " | cut -d' ' -f2)

# Get a commit SHA (or use a fake one)
GIT_SHA=$(git rev-parse HEAD)

# Create deployment
GITHUB_TOKEN="$TOKEN" REPOSITORY="$REPOSITORY" GIT_SHA="$GIT_SHA" \
  GITHUB_ORG="$GITHUB_ORG" ./scripts/create-deployment.sh
```

**Expected output:**
- "Creating GitHub deployment..."
- Shows your configuration
- "Successfully created GitHub deployment"
- JSON response with deployment details
- "💾 Deployment ID: <number>"

**If it fails:**
- Verify `REPOSITORY` is correct (without organization prefix)
- Check that `GIT_SHA` is a valid 40-character SHA
- Ensure your GitHub App has Deployments: Read & Write permission

### 3.3 Test Status Updates

```bash
source .env

# Get token
TOKEN=$(./scripts/github-app-auth.sh 2>/dev/null | grep "^Token: " | cut -d' ' -f2)

# From previous test, use the DEPLOYMENT_ID
DEPLOYMENT_ID="<id-from-previous-test>"

# Update to in_progress
GITHUB_TOKEN="$TOKEN" REPOSITORY="$REPOSITORY" \
  DEPLOYMENT_ID="$DEPLOYMENT_ID" DEPLOY_STATE="in_progress" \
  GITHUB_ORG="$GITHUB_ORG" ./scripts/update-deployment-status.sh
```

**Expected output:**
- "Updating GitHub deployment status..."
- Shows configuration
- "Successfully updated deployment status to: in_progress"
- JSON response

**If it fails:**
- Verify `DEPLOYMENT_ID` is correct
- Check that deployment exists (from previous test)
- Ensure token is still valid

## Phase 4: Full Workflow Testing (15 minutes)

### 4.1 Run Simulation

```bash
source .env
./scripts/deploy-simulation.sh
```

**Expected sequence:**
1. Gets latest commit SHA
2. Authenticates with GitHub
3. Creates deployment
4. Updates status to in_progress
5. Simulates work (3 seconds)
6. Updates status to success

**Timeline:**
- Auth: ~2 seconds
- Create: ~2 seconds
- Updates: ~1 second each
- Total: ~10 seconds

### 4.2 Verify on GitHub

After running the simulation:
1. Go to your repository on GitHub
2. Click the **Deployments** tab
3. You should see a deployment with:
   - ✅ Status: "success"
   - Environment: "staging"
   - Commit: shows the SHA
   - Timestamp: recent

## Phase 5: Interactive Testing (10 minutes)

### 5.1 Run Interactive Example

```bash
source .env
./examples/deploy-example.sh
```

This will:
1. Ask you to select a commit (shows recent commits)
2. Authenticate with GitHub
3. Create a deployment for that commit
4. Update status to in_progress
5. Simulate 10 seconds of work
6. Update status to success

**Features:**
- Press Enter to use latest commit
- Or paste a commit SHA
- Shows all steps with progress

## Phase 6: Error Handling Testing (10 minutes)

### 6.1 Test with Invalid Token

```bash
GITHUB_TOKEN="invalid-token" REPOSITORY="test" DEPLOYMENT_ID="123" \
  DEPLOY_STATE="success" ./scripts/update-deployment-status.sh
```

**Expected:**
- Error message about authentication
- HTTP status code 401

### 6.2 Test with Invalid Deployment ID

```bash
source .env
TOKEN=$(./scripts/github-app-auth.sh 2>/dev/null | grep "^Token: " | cut -d' ' -f2)

GITHUB_TOKEN="$TOKEN" REPOSITORY="$REPOSITORY" DEPLOYMENT_ID="999999999" \
  DEPLOY_STATE="success" GITHUB_ORG="$GITHUB_ORG" \
  ./scripts/update-deployment-status.sh
```

**Expected:**
- Error about deployment not found
- HTTP status code 404

### 6.3 Test with Invalid Repository

```bash
source .env
TOKEN=$(./scripts/github-app-auth.sh 2>/dev/null | grep "^Token: " | cut -d' ' -f2)

GITHUB_TOKEN="$TOKEN" REPOSITORY="non-existent-repo" GIT_SHA="abc123def456..." \
  GITHUB_ORG="$GITHUB_ORG" ./scripts/create-deployment.sh
```

**Expected:**
- Error about repository not found
- HTTP status code 404

## Phase 7: Multiple Environment Testing (5 minutes)

### 7.1 Deploy to Production

```bash
source .env

# Set production environment
export ENVIRONMENT="production"
export IS_PRODUCTION="true"

# Run simulation
./scripts/deploy-simulation.sh
```

### 7.2 Deploy to Multiple Environments

```bash
for ENV in staging development production; do
  echo "Deploying to: $ENV"
  source .env
  export ENVIRONMENT="$ENV"
  ./scripts/deploy-simulation.sh
  sleep 2
done
```

## Phase 8: Integration Testing (Optional, 15 minutes)

### 8.1 Test with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy with POC

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up scripts
        run: cp -r /Users/sergiosantiago/projects/personal/github-deployment-poc/scripts .
      
      - name: Deploy
        env:
          GITHUB_APP_ID: ${{ secrets.GH_APP_ID }}
          GITHUB_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
          GITHUB_APP_INSTALLATION_ID: ${{ secrets.GH_APP_INSTALLATION_ID }}
          REPOSITORY: ${{ github.repository }}
          GITHUB_ORG: ${{ github.repository_owner }}
        run: |
          source .env
          ./scripts/deploy-simulation.sh
```

### 8.2 Add Secrets to GitHub

1. Go to your repo Settings → Secrets and variables → Actions
2. Add these secrets:
   - `GH_APP_ID`: Your App ID
   - `GH_APP_PRIVATE_KEY`: Your private key (full PEM)
   - `GH_APP_INSTALLATION_ID`: Your Installation ID

## Test Checklist

- [ ] Phase 1: GitHub App created and credentials obtained
- [ ] Phase 2: .env file configured with all required values
- [ ] Phase 3.1: Authentication script works
- [ ] Phase 3.2: Deployment creation script works
- [ ] Phase 3.3: Status update script works
- [ ] Phase 4.1: Full simulation workflow works
- [ ] Phase 4.2: Deployment visible on GitHub
- [ ] Phase 5: Interactive example works
- [ ] Phase 6.1: Invalid token error handled
- [ ] Phase 6.2: Invalid deployment error handled
- [ ] Phase 6.3: Invalid repository error handled
- [ ] Phase 7: Multiple environments tested
- [ ] Phase 8: (Optional) GitHub Actions integration tested

## Troubleshooting

### "Failed to get GitHub App installation access token"
- Check `GITHUB_APP_ID` is correct
- Verify `GITHUB_APP_PRIVATE_KEY` includes `-----BEGIN` and `-----END` lines
- Confirm `GITHUB_APP_INSTALLATION_ID` is correct
- Ensure app is installed on your account

### "Failed to create GitHub deployment"
- Check `REPOSITORY` name (without org prefix)
- Verify `GIT_SHA` is a valid 40-char SHA or ref
- Confirm GitHub App has Deployments: Read & Write permission

### "Failed to extract token"
- Check error message in script output
- Verify environment variables are loaded (`source .env`)
- Ensure curl and jq are installed

### Scripts not executable
```bash
chmod +x /Users/sergiosantiago/projects/personal/github-deployment-poc/scripts/*.sh
chmod +x /Users/sergiosantiago/projects/personal/github-deployment-poc/examples/*.sh
```

## Support

For detailed information:
- README.md - Full documentation
- QUICKSTART.md - 5-minute setup
- ARCHITECTURE.md - Technical details

Each script also contains comments explaining what it does.
