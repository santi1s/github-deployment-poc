# GitHub Commit Status vs Deployments API - The Missing Piece

## The Root Cause (Finally Found!)

Your deployments were being created successfully, but **weren't showing on commit pages** because you were missing a crucial step: **Creating a commit status**.

GitHub has **two separate, independent APIs** that must both be used to get full deployment visibility:

### 1. Deployments API (What You Were Using)
```
POST /repos/{owner}/{repo}/deployments
```
- Creates deployment records
- Stores deployment metadata
- Updates deployment status (pending → in_progress → success)
- Makes deployments visible in the `/deployments` tab
- **Does NOT** create commit page badges

### 2. Statuses API (What Was Missing)
```
POST /repos/{owner}/{repo}/statuses/{sha}
```
- Creates commit status badges
- Renders colored indicators on commit pages
- Shows in "checks" section on commit
- Links to external tools/dashboards
- **Required** for commit page visibility

---

## The Solution

You need to call **both APIs**:

1. **First**: Create a deployment (Deployments API)
2. **Then**: Create a commit status (Statuses API)

The POC now does this automatically in `deploy-simulation.sh`:

```bash
# Step 3: Create deployment
bash scripts/create-deployment.sh

# Step 4: Update deployment status
bash scripts/update-deployment-status.sh

# Step 5: Create commit status ← THIS WAS MISSING
bash scripts/create-commit-status.sh
```

---

## What You See Now

### Before (Without Commit Status)
```
Commit page: ❌ No deployment info
Deployments tab: ✅ Shows deployment
API response: ✅ Returns deployment data
```

### After (With Commit Status)
```
Commit page: ✅ Shows "All checks have passed"
              ✅ Shows "deploy/staging - Deployed to staging"
              ✅ Shows "Details" link to deployments page
Deployments tab: ✅ Shows deployment
API response: ✅ Returns deployment data + status
```

---

## Technical Details

### Commit Status Structure

The Statuses API endpoint accepts:

```bash
POST /repos/{owner}/{repo}/statuses/{sha}

{
  "state": "success|failure|pending|error",
  "description": "Deployed to staging",
  "context": "deploy/staging",
  "target_url": "https://github.com/org/repo/deployments"
}
```

**Parameters:**
- `state`: Final status indicator
- `description`: What appears on the commit page
- `context`: Groups multiple statuses (e.g., "deploy/staging", "test/unit")
- `target_url`: Where the "Details" link goes

### The Key Insight

```
Deployment Record ≠ Commit Badge

You can:
✅ Create deployment without creating status → Works in API, not on UI
❌ Create status without deployment → Less useful, status without context
✅ Create both → Full integration, everything visible everywhere
```

---

## Why GitHub Designed It This Way

This separation provides flexibility:

1. **Multiple Status Types**: One commit can have many statuses (tests, builds, deploys)
2. **Different Permissions**: Deployment creation vs. status creation can have different permission levels
3. **External CI/CD**: CI systems (GitHub Actions, Jenkins, etc.) can create statuses without creating deployments
4. **Custom Tools**: Any tool can create a status badge, not just deployment tools

---

## Complete Workflow

### Step-by-Step

```bash
# 1. User pushes code
git push origin main

# 2. Your script detects the commit
GIT_SHA=$(git rev-parse HEAD)

# 3. Create deployment record
curl -X POST /repos/{owner}/{repo}/deployments \
  -d '{
    "ref": "'$GIT_SHA'",
    "environment": "staging"
  }'
# Returns: { "id": 12345, "sha": "abc123..." }

# 4. Update deployment status (lifecycle)
curl -X POST /repos/{owner}/{repo}/deployments/12345/statuses \
  -d '{
    "state": "in_progress"
  }'

# ... do deployment work ...

# 5. Complete deployment
curl -X POST /repos/{owner}/{repo}/deployments/12345/statuses \
  -d '{
    "state": "success"
  }'

# 6. Create commit status (THIS WAS MISSING!)
curl -X POST /repos/{owner}/{repo}/statuses/abc123... \
  -d '{
    "state": "success",
    "context": "deploy/staging",
    "description": "Deployed to staging",
    "target_url": "https://github.com/owner/repo/deployments"
  }'
```

### What GitHub Does After Step 6

- ✅ Renders green checkmark on commit page
- ✅ Shows "All checks have passed" summary
- ✅ Displays status context: "deploy/staging"
- ✅ Shows description: "Deployed to staging"
- ✅ Adds "Details" link

---

## New Script: `create-commit-status.sh`

Created to encapsulate commit status creation:

```bash
#!/bin/bash

# Usage:
GITHUB_TOKEN="token" \
REPOSITORY="repo" \
GIT_SHA="abc123" \
STATE="success" \
ENVIRONMENT="staging" \
GITHUB_ORG="santi1s" \
./scripts/create-commit-status.sh
```

**Required Variables:**
- `GITHUB_TOKEN`: GitHub API token
- `REPOSITORY`: Repository name
- `GIT_SHA`: Commit SHA
- `STATE`: One of: pending, success, failure, error

**Optional Variables:**
- `GITHUB_ORG`: Organization (default: santi1s)
- `ENVIRONMENT`: Environment name (default: staging)
- `DESCRIPTION`: Status description (default: "Deployment to {env}")
- `CONTEXT`: Status context (default: "deploy/{env}")
- `DEPLOYMENT_URL`: Link target (default: deployments page)

---

## Testing

Run the updated simulation:

```bash
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
source .env
./scripts/deploy-simulation.sh
```

You should see:

```
═══════════════════════════════════════════════════════════
   GitHub Deployment Simulation
═══════════════════════════════════════════════════════════

Step 1/4: Getting latest commit SHA...
✅ Found commit: abc123...

Step 2/4: Authenticating with GitHub...
✅ Authentication successful

Step 3/4: Creating GitHub deployment...
✅ Deployment created with ID: 12345

Step 4/4: Simulating deployment progress...
  → Updating status to: in_progress
    ✅ Status updated
  ⏳ Working... 1/3
  → Updating status to: success
    ✅ Deployment completed successfully

Step 5/5: Creating commit status badge...
✅ Commit status badge created

═══════════════════════════════════════════════════════════
✅ Deployment simulation completed successfully!
═══════════════════════════════════════════════════════════
```

Then check your commit page:
```
https://github.com/santi1s/github-deployment-poc/commit/[GIT_SHA]
```

You should see:
```
✅ All checks have passed

deploy/staging - Deployed to staging
[Details link]
```

---

## Debugging

If commit status still doesn't show:

1. **Check deployment exists**:
   ```bash
   GITHUB_TOKEN="$TOKEN" ./scripts/list-deployments.sh
   ```

2. **Check commit status was created**:
   ```bash
   curl -H "Authorization: Bearer $TOKEN" \
     https://api.github.com/repos/santi1s/github-deployment-poc/commits/abc123/statuses
   ```
   Should return `[]` if no statuses, or array of status objects if created.

3. **Verify permissions**: Make sure your GitHub App has "Statuses: Read & Write"

4. **Check context**: Status `context` should be visible on the commit page badge

---

## GitHub Documentation References

- [Deployments API](https://docs.github.com/en/rest/deployments/deployments)
- [Deployment Statuses API](https://docs.github.com/en/rest/deployments/statuses)
- [Commit Statuses API](https://docs.github.com/en/rest/commits/statuses)
- [GitHub App Permissions](https://docs.github.com/en/apps/building-github-apps/managing-permissions-for-github-apps)

---

## Summary

The missing piece was **calling the Statuses API** to create commit status badges. Without it:
- ❌ Deployments don't appear on commit pages
- ❌ No badges or check indicators
- ✅ But deployments do work in the API and `/deployments` tab

This is now fixed in the POC, and deployments will fully display on commit pages when you run the updated `deploy-simulation.sh`.
