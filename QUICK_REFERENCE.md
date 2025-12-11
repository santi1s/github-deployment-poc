# Quick Reference Guide

## The Two APIs You Need

| API | Purpose | When to Call | What It Creates |
|-----|---------|--------------|-----------------|
| **Deployments API** | Create & track deployments | On every deploy | Deployment records in `/deployments` tab |
| **Statuses API** | Create commit badges | After deploy succeeds | Green checkmark on commit page |

## The Scripts

### Automatic (Recommended)
```bash
./scripts/deploy-simulation.sh
```
Does everything automatically:
1. Gets commit SHA
2. Creates deployment
3. Updates status (in_progress → success)
4. Creates commit status badge ✨

### Manual (If Needed)

**Step 1: Authenticate**
```bash
GITHUB_TOKEN=$(./scripts/github-app-auth.sh | grep '^Token:' | cut -d' ' -f2)
```

**Step 2: Create Deployment**
```bash
GITHUB_TOKEN="$TOKEN" \
REPOSITORY="github-deployment-poc" \
GIT_SHA="abc123..." \
./scripts/create-deployment.sh
# Returns: DEPLOYMENT_ID
```

**Step 3: Update Status**
```bash
GITHUB_TOKEN="$TOKEN" \
REPOSITORY="github-deployment-poc" \
DEPLOYMENT_ID="12345" \
DEPLOY_STATE="success" \
./scripts/update-deployment-status.sh
```

**Step 4: Create Commit Status ⭐ (THE IMPORTANT ONE)**
```bash
GITHUB_TOKEN="$TOKEN" \
REPOSITORY="github-deployment-poc" \
GIT_SHA="abc123..." \
STATE="success" \
ENVIRONMENT="staging" \
./scripts/create-commit-status.sh
```

## View Results

### On GitHub UI
```
https://github.com/santi1s/github-deployment-poc/commit/[GIT_SHA]
```
Should show:
- ✅ All checks have passed
- deploy/staging - Deployed to staging
- [Details] link

### In Deployments Tab
```
https://github.com/santi1s/github-deployment-poc/deployments
```
Shows:
- All deployments
- Status history
- Environment details

### Via API
```bash
# List deployments
GITHUB_TOKEN="$TOKEN" ./scripts/list-deployments.sh

# Get status history
GITHUB_TOKEN="$TOKEN" \
DEPLOYMENT_ID="12345" \
./scripts/get-deployment-status.sh

# Check commit statuses
curl -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/santi1s/github-deployment-poc/commits/abc123/statuses
```

## Common Issues

| Problem | Solution |
|---------|----------|
| No badge on commit | Did you call `create-commit-status.sh`? |
| 404 on deployment | Make sure DEPLOYMENT_ID exists |
| Auth fails | Check GITHUB_APP_ID and GITHUB_APP_PRIVATE_KEY in `.env` |
| No deployments appear | Check `REPOSITORY` and `GITHUB_ORG` in `.env` |
| Permission denied | Add Statuses permission to GitHub App |

## Permission Requirements

Your GitHub App needs:
```
✅ Deployments: Read & Write
✅ Statuses: Read & Write
✅ Contents: Read
```

## Environment Variables

**Required:**
```bash
GITHUB_APP_ID="2453299"
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA..."
GITHUB_APP_INSTALLATION_ID="99095062"
REPOSITORY="github-deployment-poc"
GITHUB_ORG="santi1s"
```

**Optional:**
```bash
ENVIRONMENT="staging"  # Default: staging
HTTP_PROXY=""         # If needed
```

## API Endpoints Summary

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Create deployment | POST | `/repos/{owner}/{repo}/deployments` |
| List deployments | GET | `/repos/{owner}/{repo}/deployments` |
| Get deployment | GET | `/repos/{owner}/{repo}/deployments/{id}` |
| Update deployment status | POST | `/repos/{owner}/{repo}/deployments/{id}/statuses` |
| Get deployment statuses | GET | `/repos/{owner}/{repo}/deployments/{id}/statuses` |
| Create commit status | POST | `/repos/{owner}/{repo}/statuses/{sha}` |
| Get commit statuses | GET | `/repos/{owner}/{repo}/commits/{sha}/statuses` |

## Key Insight

```
✅ You must call BOTH APIs:
   1. Deployments API (records)
   2. Statuses API (badges)

❌ Calling only Deployments API:
   - Creates records ✅
   - Shows in /deployments tab ✅
   - Shows on commit page ❌

❌ Calling only Statuses API:
   - Shows on commit page ✅
   - Shows in /deployments tab ❌
   - Lost deployment context ❌
```

## Testing Workflow

```bash
# 1. Setup
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
source .env

# 2. Run deployment
./scripts/deploy-simulation.sh

# 3. Get commit SHA from output
# Copy the "Commit: abc123..." line

# 4. Check on GitHub (wait 5-10 seconds)
# https://github.com/santi1s/github-deployment-poc/commit/abc123

# 5. Should see:
# ✅ All checks have passed
# deploy/staging - Deployed to staging
```

## Documentation Files

For details, see:
- `README.md` - Full API reference
- `SOLUTION_SUMMARY.md` - Overview of the fix
- `COMMIT_STATUS_EXPLANATION.md` - Technical deep-dive
- `DEPLOYMENTS_EXPLAINED.md` - Deployment concepts
- `PERMISSIONS_FIX.md` - Permission requirements
- `GITHUB_PERMISSIONS_ANALYSIS.md` - Why permissions matter
- `ARCHITECTURE.md` - System design
- `TESTING.md` - Test scenarios

## Support

Having issues? Check:
1. Permissions in GitHub App settings
2. Variables in `.env` are correct
3. Commit SHA is pushed to GitHub
4. Try calling API manually to debug
5. Check GitHub API response for errors

---

**TL;DR**: Run `./scripts/deploy-simulation.sh` and check your commit page. Deployments should now display with badges! ✅
