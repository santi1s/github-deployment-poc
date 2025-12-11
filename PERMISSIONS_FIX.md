# Fixing GitHub App Permissions for Deployment Display

## The Problem

You have deployments created and visible in:
- ✅ `/deployments` tab on GitHub
- ✅ List from API (`list-deployments.sh`)

But they're NOT showing:
- ❌ On the commit page itself
- ❌ As deployment badges on commits

## Root Cause Analysis

Based on official GitHub documentation, your deployment visibility issue is likely caused by **one of these missing permissions**:

### Current State (What You Have):
- ✅ **Deployments**: Read & Write
- ✅ **Contents**: Read

### What's Likely Missing:

**Option 1: Statuses Permission (MOST LIKELY)**
- ❌ **Statuses**: Read (or Read & Write)
- GitHub's REST API requires this permission to create and display commit statuses
- Even though deployments are created, they won't display on commit pages without status permission
- [GitHub REST API Reference: Commit Statuses](https://docs.github.com/en/rest/commits/statuses)

**Option 2: Checks Permission (ALTERNATIVE)**
- ❌ **Checks**: Read & Write
- Some GitHub features use Checks API instead of traditional statuses
- May be required in addition to or instead of Statuses

### Why This Matters:

GitHub has **three separate systems** for commit metadata:
1. **Deployments API** - Creates deployment records (what you're using)
2. **Statuses API** - Updates commit status indicators on the UI (needed for display)
3. **Checks API** - Modern check runs with detailed output

**Deployments are created successfully** but **won't display on commit pages** without the corresponding Status or Check permissions to render them in the UI.

## Solution: Add Statuses Permission

### Step 1: Go to Your GitHub App Settings

Navigate to:
```
https://github.com/settings/apps/github-deployment-poc
```

Or manually:
1. Go to https://github.com/settings/apps
2. Click on **"github-deployment-poc"**

### Step 2: Update Repository Permissions

Look for **"Repository permissions"** section:

**Current state:**
```
Deployments: Read & write  ✅
Contents: Read             ✅
Statuses: (not set)        ❌ MISSING
```

**Change to:**
```
Deployments: Read & write  ← Keep this
Contents: Read             ← Keep this
Statuses: Read & write     ← ADD THIS (required for deployment display)
```

**Note**: Some GitHub App settings interfaces may show this as "Commit statuses" instead of "Statuses".

### Step 3: Save Changes

1. Scroll down to find **"Update"** or **"Save"** button
2. Click it
3. GitHub may show a confirmation message

### Step 4: Re-authorize the App

The app might ask you to re-authorize:
1. You may get a notification in your repository settings
2. Go to your repo: https://github.com/santi1s/github-deployment-poc
3. Settings → **Installed GitHub Apps**
4. Find **"github-deployment-poc"**
5. Click **"Configure"** if needed
6. Approve any new permission requests

### Step 5: Test Again

```bash
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
source .env

# Create a new deployment to test
./scripts/deploy-simulation.sh
```

### Step 6: Verify

1. Go to your commit: https://github.com/santi1s/github-deployment-poc/commits
2. Find the new commit SHA from the simulation
3. You should now see a **deployment badge** showing the staging environment

## What Each Permission Does

| Permission | What It Enables |
|---|---|
| **Deployments: Read** | Read deployment records |
| **Deployments: Write** | Create/update deployments ✅ You're using this |
| **Contents: Read** | Read commits, files, branches |
| **Contents: Write** | Modify repository content |
| **Statuses: Read** | Read commit status information |
| **Statuses: Write** | Create/update commit statuses and deployment badges ✅ NEEDED |
| **Metadata: Read** | Basic repository info |

### For Complete Deployment Functionality:

**To create deployments:**
- ✅ `Deployments: Write` (create deployment records)

**To display deployments on commits:**
- ✅ `Contents: Read` (identify commits)
- ⚠️ `Statuses: Read & Write` (render deployment badges on commit pages)

**The Key Insight:**
Creating a deployment (API call succeeds) ≠ Displaying a deployment (requires Status permission)

GitHub separates the API operation from the UI rendering. You need both permissions.

## GitHub Deployment Display Locations

With proper permissions, deployments appear in:

### 1. Commit Page
```
https://github.com/santi1s/github-deployment-poc/commit/COMMIT_SHA

Shows:
- Deployment badges for each environment
- Environment name (staging, production, etc.)
- Status
```

### 2. Deployments Tab
```
https://github.com/santi1s/github-deployment-poc/deployments

Shows:
- All deployments
- Full status history
- Timeline
```

### 3. Branch/Release Page
```
May show deployment info for releases
```

## Verification Checklist

After making changes:

- [ ] Go to GitHub App settings (https://github.com/settings/apps/github-deployment-poc/permissions)
- [ ] Verify **Deployments**: Read & write is set ✅
- [ ] Verify **Contents**: Read is set ✅
- [ ] Verify **Statuses**: Read & write is set ⚠️ (ADD THIS if missing)
- [ ] Saved changes
- [ ] Re-authorized the app if prompted by GitHub
- [ ] Went to repo settings and re-configured the app if needed
- [ ] Created a new deployment with `./scripts/deploy-simulation.sh`
- [ ] Waited 5-10 seconds for GitHub to process the deployment
- [ ] Checked the commit page for deployment badge: https://github.com/santi1s/github-deployment-poc/commit/[COMMIT_SHA]
- [ ] Checked `/deployments` tab to confirm deployments exist

## Still Not Showing?

If deployments still don't appear on the commit page after fixing permissions:

### Check These:

1. **Verify Statuses Permission is Added**
   - Go to: https://github.com/settings/apps/github-deployment-poc/permissions
   - Look for **"Statuses"** or **"Commit statuses"** in Repository permissions
   - If NOT present, this is likely your issue
   - Add **Statuses: Read & Write** and save

2. **Re-authorize the App After Permission Change**
   - GitHub may require you to re-install the app on your repository
   - Go to: https://github.com/santi1s/github-deployment-poc/settings/installations
   - Find **github-deployment-poc** app
   - Click **"Configure"** or **"Update"**
   - Review and approve the new **Statuses** permission request

3. **Correct Commit SHA**
   - Verify the commit SHA matches what was deployed
   - Check: `git log --oneline` to see commit list
   - Make sure you're using the exact SHA from the deployment

4. **Wait for GitHub Sync**
   - GitHub may take 5-10 seconds to render deployment badges
   - Try refreshing the commit page (Cmd+Shift+R for hard refresh)

5. **Branch Settings**
   - Make sure you're viewing a public or accessible branch
   - Some enterprise settings restrict deployment display

6. **App Installation Status**
   - Go to: https://github.com/settings/installations
   - Check that the app is installed for your repository
   - Verify no "warning" status is shown for permissions

7. **API vs UI Consistency**
   - Verify deployments exist via API:
     ```bash
     cd /Users/sergiosantiago/projects/personal/github-deployment-poc
     source .env
     ./scripts/list-deployments.sh
     ```
   - If they exist in API but not in UI, check that Statuses permission was saved
   - Sometimes GitHub's UI lags behind API - wait a few seconds and refresh

### The Root Issue Most Likely:

If you see deployments in the API and Deployments tab, but NOT on commit pages, it's almost certainly because **Statuses: Read & Write permission is missing** from your GitHub App configuration.

## Quick Reference

**Permissions URL:**
https://github.com/settings/apps/github-deployment-poc/permissions

**Installation URL:**
https://github.com/settings/installations

**Repository Settings:**
https://github.com/santi1s/github-deployment-poc/settings/installations

## Example: After Fixing

Once fixed, when you visit a commit, you should see:

```
✅ Deployed to staging by github-deployment-poc
   Status: success
   [View deployment]
```

This will appear near the commit message with a green checkmark and environment name.

## Need Help?

If you're still having issues after checking permissions:

1. Verify `.env` has correct `GITHUB_APP_ID` and `GITHUB_APP_INSTALLATION_ID`
2. Check that commits are actually being deployed:
   ```bash
   ./scripts/list-deployments.sh
   ```
3. Ensure the repository is public (private repos may have different behavior)
4. Check GitHub Status page for any outages affecting deployments display

## Security Note

Giving the app these permissions is safe:
- **Contents: Read** - Allows the app to read repository code and commit history
- **Statuses: Read & Write** - Allows the app to create deployment status badges on commits

Both are read-only at the file level and only create metadata about deployments, not modifying code.

## Official GitHub Documentation

This guide is based on official GitHub REST API documentation:

1. **Deployments API**
   - Endpoint: `POST /repos/{owner}/{repo}/deployments`
   - Requires: `Deployments: Read & Write` permission
   - [GitHub Deployments API Reference](https://docs.github.com/en/rest/deployments/deployments)

2. **Deployment Statuses API**
   - Endpoint: `POST /repos/{owner}/{repo}/deployments/{deployment_id}/statuses`
   - Requires: `Deployments: Read & Write` permission
   - [GitHub Deployment Statuses API Reference](https://docs.github.com/en/rest/deployments/statuses)

3. **Commit Statuses API**
   - Endpoint: `GET/POST /repos/{owner}/{repo}/statuses/{sha}`
   - Requires: `Statuses: Read & Write` permission
   - Needed for rendering deployment badges on commit pages
   - [GitHub Commit Statuses API Reference](https://docs.github.com/en/rest/commits/statuses)

4. **GitHub App Permissions**
   - [Complete Permissions Reference](https://docs.github.com/en/apps/building-github-apps/managing-permissions-for-github-apps)
   - See "Repository permissions" section for detailed permission descriptions

## Key Difference: API vs UI

- **API Success** ≠ **UI Display**
- Creating a deployment (API call) requires `Deployments: Write`
- Displaying deployments on commits (UI rendering) requires `Statuses: Read & Write`
- This is why you can see deployments via API and in `/deployments` tab, but not on commit pages
