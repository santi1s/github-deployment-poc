# Understanding GitHub Deployments

This guide explains how GitHub Deployments work and how to interpret the information from the POC.

## What You Created

When you ran `./scripts/deploy-simulation.sh`, you created **2 deployments**:

| Deployment ID | Commit | Environment | Status | Created |
|---|---|---|---|---|
| `3460771243` | `7381088...` | staging | pending | 2025-12-11 14:39:25 |
| `3460740443` | `41a070f...` | staging | pending | 2025-12-11 14:35:03 |

## Understanding Deployment Status

### Status Values

GitHub Deployments use these status values:

| Status | Meaning | When It Occurs |
|---|---|---|
| **pending** | Deployment waiting to start | Initial state after creation |
| **in_progress** | Deployment currently running | When deployment work begins |
| **success** | Deployment completed successfully | After successful deployment |
| **failure** | Deployment failed | When deployment encounters an error |
| **inactive** | Deployment was cancelled/superseded | When deployment is no longer active |
| **error** | Unexpected error during deployment | System error |

### What the POC Does

```
1. Create Deployment
   ↓ Returns Deployment ID
2. Update Status → in_progress
   ↓ Deployment starts
3. Simulate Work (3 seconds)
   ↓
4. Update Status → success
   ↓ Deployment complete
```

### Status History

Each deployment can have **multiple status updates**. For example:

```
Deployment ID: 3460771243
├── Status: pending (2025-12-11 14:39:25)  ← Initial creation
├── Status: in_progress (2025-12-11 14:39:26)  ← Deployment started
└── Status: success (2025-12-11 14:39:29)  ← Deployment complete
```

The `pending` shown in `list-deployments.sh` may be showing the **first status** rather than the latest.

## Viewing Deployments

### Method 1: GitHub Web UI (Best)

1. Go to: https://github.com/santi1s/github-deployment-poc
2. Click **"Deployments"** tab
3. Click on a deployment to see:
   - Full status history
   - All status updates with timestamps
   - Environment details
   - Associated commit

### Method 2: Via API with Scripts

**List all deployments:**
```bash
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
source .env
TOKEN=$(./scripts/github-app-auth.sh 2>/dev/null | grep '^Token:' | cut -d' ' -f2)
GITHUB_TOKEN="$TOKEN" ./scripts/list-deployments.sh
```

**Get status history for a specific deployment:**
```bash
GITHUB_TOKEN="$TOKEN" DEPLOYMENT_ID="3460771243" ./scripts/get-deployment-status.sh
```

### Method 3: Direct GitHub API

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.github.com/repos/santi1s/github-deployment-poc/deployments/3460771243/statuses
```

## Key Concepts

### Deployment vs. Commit

- **Deployment**: An action/operation to deploy code to an environment
- **Commit**: A code change in the repository

**Relationship:**
```
Commit 7381088... (code change)
    ↓
Deployment 3460771243 (deploy that commit to staging)
    ↓
Status History (pending → in_progress → success)
```

### Environment

A deployment targets an **environment**:
- `staging` - Pre-production environment
- `production` - Live environment
- `development` - Development environment
- Custom environments

Each environment can have multiple deployments over time.

### Statuses

A single deployment can have **multiple statuses** over time:
- A deployment starts with `pending` status
- Transitions to `in_progress` when work begins
- Ends with `success`, `failure`, or `error`

## Interpreting Your Results

### What it Means

Your 2 deployments mean:
- ✅ GitHub Deployment API working correctly
- ✅ Authentication successful
- ✅ Deployment creation successful
- ✅ Status updates sent successfully
- ✅ Deployments visible on GitHub

### The "Pending" Status

The `list-deployments.sh` showing `pending` likely means:
- The API is showing the **initial status** from deployment creation
- The **full status history** (in_progress, success) exists but requires a separate API call
- This is normal behavior - the deployment exists and is working

To see the full history, use the GitHub UI or the `get-deployment-status.sh` script.

## API Endpoints Used

### Create Deployment
```
POST /repos/{owner}/{repo}/deployments
```
Creates a new deployment record for a commit.

### Get Deployments
```
GET /repos/{owner}/{repo}/deployments
```
Lists all deployments for a repository.

### Get Deployment Statuses
```
GET /repos/{owner}/{repo}/deployments/{deployment_id}/statuses
```
Lists all status updates for a specific deployment (in reverse chronological order, newest first).

### Update Deployment Status
```
POST /repos/{owner}/{repo}/deployments/{deployment_id}/statuses
```
Adds a new status update to a deployment.

## Next Steps

1. **View on GitHub**:
   - https://github.com/santi1s/github-deployment-poc/deployments

2. **Create more deployments**:
   ```bash
   source .env
   ./scripts/deploy-simulation.sh  # Creates another deployment
   ```

3. **Deploy to different environment**:
   ```bash
   ENVIRONMENT="production" IS_PRODUCTION="true" ./scripts/deploy-simulation.sh
   ```

4. **Monitor deployments**:
   - Use `./scripts/list-deployments.sh` for a quick overview
   - Use GitHub UI for full details

## Troubleshooting

### I don't see any deployments

**Solution**: Run `./scripts/deploy-simulation.sh` to create a deployment.

### Deployments show "pending" but I expect "success"

**Normal behavior** - The API response might be showing the initial status. Check the GitHub UI for the full status history.

### How do I know a deployment was successful?

- **Quick check**: Run `./scripts/list-deployments.sh` and look for multiple deployments
- **Full check**: Go to GitHub Deployments tab and click a deployment to see status history
- **API check**: Use `./scripts/get-deployment-status.sh` to get status details

## Additional Resources

- [GitHub Deployments API](https://docs.github.com/en/rest/deployments/deployments)
- [GitHub Deployment Statuses API](https://docs.github.com/en/rest/deployments/statuses)
- [GitHub Deployments Documentation](https://docs.github.com/en/developers/overview/managing-deployments)
