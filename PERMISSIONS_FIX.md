# Fixing GitHub App Permissions for Deployment Display

## The Problem

You have deployments created and visible in:
- ✅ `/deployments` tab on GitHub
- ✅ List from API (`list-deployments.sh`)

But they're NOT showing:
- ❌ On the commit page itself
- ❌ As deployment badges on commits

## Root Cause: Missing "Contents" Permission

Your GitHub App currently has:
- ✅ **Deployments**: Read & Write

But it likely needs:
- ❌ **Contents**: Read (missing)

GitHub requires the app to have permission to **read repository contents** (commits) to link deployments to commits on the commit page.

## Solution: Add Contents Permission

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
Deployments: Read & write
Contents: (not set or Read-only)
```

**Change to:**
```
Deployments: Read & write  ← Keep this
Contents: Read             ← Add this (or Change to Read & write)
```

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
| **Deployments: Read** | Read deployment info |
| **Deployments: Write** | Create/update deployments |
| **Contents: Read** | Read commits, files, branches |
| **Contents: Write** | Modify repository content |
| **Metadata: Read** | Basic repository info |

For deployment display on commits, you need:
- `Deployments: Write` (create deployments)
- `Contents: Read` (link to commits)

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

- [ ] Go to GitHub App settings
- [ ] Verify **Deployments**: Read & write is set
- [ ] Verify **Contents**: Read is set (or Read & write)
- [ ] Saved changes
- [ ] Re-authorized the app if prompted
- [ ] Created a new deployment with `./scripts/deploy-simulation.sh`
- [ ] Checked commit page for deployment badge
- [ ] Checked `/deployments` tab to confirm deployments exist

## Still Not Showing?

If deployments still don't appear on the commit page after fixing permissions:

### Check These:

1. **Correct Commit SHA**
   - Verify the commit SHA matches what was deployed
   - Check: `git log --oneline` to see commit list

2. **Wait for GitHub Sync**
   - Sometimes takes 5-10 minutes
   - Try refreshing the page after waiting

3. **Branch Settings**
   - Make sure you're viewing a public or accessible branch
   - Some enterprise settings restrict deployment display

4. **App Installation**
   - Go to: https://github.com/settings/installations
   - Check that the app is installed for your repository
   - May need to re-install if permissions changed

5. **API vs UI Consistency**
   - Verify deployments exist via API:
     ```bash
     source .env
     ./scripts/list-deployments.sh
     ```
   - If they exist in API but not in UI, it's a GitHub rendering issue (temporary)

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

Giving the app **Contents: Read** permission is safe - it just allows the app to read your repository's code and commit history, which is necessary for linking deployments to commits.
