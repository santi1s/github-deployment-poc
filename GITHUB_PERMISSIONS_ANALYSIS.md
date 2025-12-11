# GitHub Deployment Permissions Analysis

## Executive Summary

Your GitHub deployments are being created successfully via the API, but they're not displaying on commit pages because your GitHub App is **missing the "Statuses" (or "Commit statuses") permission**.

**Current Permissions:**
- ✅ Deployments: Read & Write
- ✅ Contents: Read
- ❌ Statuses: Missing (REQUIRED for commit page display)

---

## The Problem: API Success ≠ UI Display

GitHub has **three separate systems** for handling commit metadata:

### 1. Deployments API
- **What it does**: Creates and manages deployment records
- **What you're using**: ✅ Working correctly
- **Permission needed**: `Deployments: Read & Write`
- **Endpoint**: `POST /repos/{owner}/{repo}/deployments`
- **Your status**: ✅ This part works - deployments appear in `/deployments` tab and API calls succeed

### 2. Deployment Statuses API
- **What it does**: Updates the status of a deployment (pending → in_progress → success)
- **Permission needed**: `Deployments: Read & Write`
- **Your status**: ✅ This works - you can update deployment statuses

### 3. Commit Statuses / Checks API
- **What it does**: Renders badges and status indicators **on the commit page itself**
- **Permission needed**: `Statuses: Read & Write` (also called "Commit statuses")
- **Endpoint**: `POST /repos/{owner}/{repo}/statuses/{sha}`
- **Your status**: ❌ **This is what's missing** - deployments don't show on commit pages without this

---

## Why This Design?

GitHub separates permissions and APIs intentionally:

1. **Create Deployment** (Deployments API)
   - Records that a deployment happened
   - Requires: `Deployments: Write`
   - Visible in: GitHub API, `/deployments` tab

2. **Display Deployment on Commit** (Statuses API)
   - Renders the deployment badge on the commit page
   - Requires: `Statuses: Write`
   - Visible in: Commit page UI

An app could have permission to:
- ✅ Create deployments but ❌ not display them
- ❌ Create deployments but ✅ display them via another method
- Both or neither

---

## The Solution

### Step 1: Add Statuses Permission

Go to your GitHub App settings:
```
https://github.com/settings/apps/github-deployment-poc/permissions
```

In the **"Repository permissions"** section, find or add:
```
Statuses: Read & Write
```

Your final permission set should be:
```
✅ Contents: Read
✅ Deployments: Read & write
✅ Statuses: Read & write  ← ADD THIS
```

### Step 2: Save and Re-authorize

1. Click **"Update"** or **"Save"** on the permissions page
2. GitHub may ask you to re-authorize the app
3. Go to your repository: https://github.com/santi1s/github-deployment-poc
4. Navigate to: **Settings → Installed GitHub Apps → github-deployment-poc**
5. Click **"Configure"** and approve the new permission request

### Step 3: Test

```bash
cd /Users/sergiosantiago/projects/personal/github-deployment-poc
source .env
./scripts/deploy-simulation.sh
```

Then visit a commit page:
```
https://github.com/santi1s/github-deployment-poc/commit/[COMMIT_SHA]
```

You should now see:
```
✅ Deployed to staging
   Status: success
   [View deployment]
```

---

## Technical Details from GitHub API Docs

### Deployments Endpoint
```
POST /repos/{owner}/{repo}/deployments
Requires: Deployments: Read & Write
```

Creates a deployment record. **Succeeds without Statuses permission.**

### Deployment Statuses Endpoint
```
POST /repos/{owner}/{repo}/deployments/{deployment_id}/statuses
Requires: Deployments: Read & Write
```

Updates a deployment's status. **Works without Statuses permission.**

### Commit Statuses Endpoint
```
POST /repos/{owner}/{repo}/statuses/{sha}
Requires: Statuses: Read & Write
```

Creates or updates a status badge on a commit. **This is what displays on the commit page.**

---

## Why You See This Behavior

| Action | Requires | Your Current Status |
|--------|----------|-------------------|
| Create deployment | Deployments: Write | ✅ Works |
| Update deployment status | Deployments: Write | ✅ Works |
| List deployments | Deployments: Read | ✅ Works |
| Show in `/deployments` tab | Deployments: Read | ✅ Works |
| Display badge on commit page | Statuses: Write | ❌ Missing |
| Update commit status color | Statuses: Write | ❌ Missing |

---

## Proof from Documentation

From [GitHub REST API Commit Statuses](https://docs.github.com/en/rest/commits/statuses):

> **Permissions Required:**
> - Repository: Statuses (read/write)
>
> This permission allows the app to create and update the statuses that appear on commits.

From [GitHub App Permissions Reference](https://docs.github.com/en/apps/building-github-apps/managing-permissions-for-github-apps):

> **Statuses** - Provides access to commit statuses, enabling integration with CI/CD systems and deployment tracking.

---

## Common Questions

### Q: Why does the API call succeed but nothing shows up?

**A:** GitHub's Deployments API and Statuses API are separate. You have permission for one but not the other. The API call succeeds (creating the deployment record), but GitHub has no permission to **display** it on the commit page.

### Q: If I add Statuses permission, will old deployments show up?

**A:** No, you'll need to create new deployments **after** adding the permission. Old deployments were created without the Statuses permission, so GitHub didn't render them.

### Q: Is it safe to add Statuses permission?

**A:** Yes, it's safe. Statuses are metadata about deployments, not code changes. The app can only create status badges, not modify your code.

### Q: Do I need Checks API too?

**A:** Not unless you want more detailed check runs. For basic deployment display, Statuses is sufficient.

---

## Next Steps

1. ✅ You've diagnosed the issue: **Missing Statuses permission**
2. 📋 Next: Add **Statuses: Read & Write** to your GitHub App
3. ⚙️ Then: Re-authorize the app on your repository
4. 🧪 Finally: Test with `./scripts/deploy-simulation.sh` and verify commit page shows deployment badge

---

## References

- [GitHub Deployments API](https://docs.github.com/en/rest/deployments/deployments)
- [GitHub Deployment Statuses API](https://docs.github.com/en/rest/deployments/statuses)
- [GitHub Commit Statuses API](https://docs.github.com/en/rest/commits/statuses)
- [GitHub App Permissions](https://docs.github.com/en/apps/building-github-apps/managing-permissions-for-github-apps)
