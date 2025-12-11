# GitHub Deployment POC - Architecture

## Overview

This POC demonstrates a simple, script-based approach to GitHub Deployment creation and status tracking without Argo Workflows.

## Components

### 1. Authentication (`scripts/github-app-auth.sh`)
- Uses GitHub App credentials to generate a JWT token
- Exchanges JWT for an installation access token
- Token valid for 10 minutes
- No external dependencies beyond standard tools

**Key steps:**
1. Load GitHub App ID and private key
2. Create JWT with 10-minute expiry
3. Sign JWT with private key using RSA SHA256
4. POST JWT to GitHub API to get installation token
5. Return access token for API calls

### 2. Deployment Creation (`scripts/create-deployment.sh`)
- Creates a GitHub Deployment resource
- Requires: git SHA, repository name, environment name
- Sets deployment configuration:
  - `auto_merge: false`
  - `required_contexts: []`
  - `transient_environment: false`
  - `production_environment: <configurable>`

**Return value:**
- Deployment ID needed for status updates

### 3. Status Updates (`scripts/update-deployment-status.sh`)
- Updates deployment status to: `in_progress`, `success`, `failure`, `pending`
- Can include log URL for linking to CI/CD logs
- Supports custom descriptions per status

**Valid states:**
```
pending      → in_progress → success
                         ↓
                       failure
```

### 4. Simulation (`scripts/deploy-simulation.sh`)
- End-to-end workflow demonstration
- Automates: auth → create → in_progress → success
- Useful for testing and demonstration

### 5. Interactive Example (`examples/deploy-example.sh`)
- Step-by-step guided deployment
- Prompts for commit selection
- Shows all intermediate steps

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│ GitHub App Credentials (.env)                          │
│ - GITHUB_APP_ID                                        │
│ - GITHUB_APP_PRIVATE_KEY                               │
│ - GITHUB_APP_INSTALLATION_ID                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
         ┌──────────────────┐
         │ github-app-auth  │
         │ Generate JWT     │
         │ Exchange for     │
         │ access token     │
         └────────┬─────────┘
                  │
        ┌─────────▼──────────┐
        │  GITHUB_TOKEN      │
        └─────────┬──────────┘
                  │
     ┌────────────┼────────────┐
     │            │            │
     ▼            ▼            ▼
  CREATE      UPDATE STATUS  ...
  DEPLOYMENT  in_progress
     │        success
     │        failure
     └─────────┬──────────────┐
              ▼              ▼
        DEPLOYMENT ID    GitHub API
        (for status      Updates
         updates)        Statuses
```

## API Endpoints Used

### 1. Create Deployment
```
POST /repos/{owner}/{repo}/deployments
Content: {
  ref,                           // git SHA
  environment,                   // staging/prod
  auto_merge,                    // usually false
  required_contexts,             // []
  transient_environment,         // false
  production_environment         // true/false
}
Returns: { id, ... }
```

### 2. Update Deployment Status
```
POST /repos/{owner}/{repo}/deployments/{deployment_id}/statuses
Content: {
  state,                         // in_progress/success/failure/pending
  environment,                   // staging/prod
  description,                   // status message
  log_url                        // optional log link
}
Returns: { state, ... }
```

## Error Handling

The scripts include:
- ✅ HTTP status code validation
- ✅ JSON response validation
- ✅ Required field verification
- ✅ Readable error messages
- ❌ No automatic retry logic (can be added)

## Security Considerations

**What's safe:**
- GitHub App authentication (better than personal tokens)
- No secrets in code (use `.env` file, excluded from git)
- Read-only access for Contents (only needs Deployments write)
- JWT expires after 10 minutes

**What to improve:**
- Add HTTP status code error handling
- Implement retry logic for transient failures
- Add request signing/validation
- Log audit trail of deployments
- Add deployment failure rollback logic

## Integration Points

### With CI/CD Systems
```bash
# In your CI/CD pipeline:
source .env
TOKEN=$(./scripts/github-app-auth.sh | grep "^Token:" | cut -d' ' -f2)
DEPLOYMENT_ID=$(GITHUB_TOKEN="$TOKEN" ./scripts/create-deployment.sh | grep ID)
GITHUB_TOKEN="$TOKEN" DEPLOYMENT_ID="$DEPLOYMENT_ID" DEPLOY_STATE="in_progress" \
  ./scripts/update-deployment-status.sh
# ... do actual deployment ...
GITHUB_TOKEN="$TOKEN" DEPLOYMENT_ID="$DEPLOYMENT_ID" DEPLOY_STATE="success" \
  ./scripts/update-deployment-status.sh
```

### With GitHub Actions
Place scripts in a GitHub Actions workflow:
```yaml
- name: Deploy
  env:
    GITHUB_APP_ID: ${{ secrets.GH_APP_ID }}
    GITHUB_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
    GITHUB_APP_INSTALLATION_ID: ${{ secrets.GH_APP_INSTALLATION_ID }}
  run: ./scripts/deploy-simulation.sh
```

### With Other CI/CD (GitLab, Jenkins, etc.)
Adapt the scripts to your platform and pass credentials via CI/CD secrets.

## Comparison with Argo Workflows

| Feature | POC | Argo Workflows |
|---------|-----|---|
| Complexity | Low | High |
| Setup time | 5 min | 1-2 hours |
| Kubernetes required | No | Yes |
| Dependencies | curl, jq | Argo, Kubernetes |
| Scaling | Single machine | Cluster-wide |
| Workflow visualization | None | Built-in UI |
| Status tracking | Manual | Automatic |
| Error handling | Basic | Advanced |
| Ideal for | Testing, simple deploys | Complex multi-step workflows |

## Files Overview

```
.
├── README.md                           # Full documentation
├── QUICKSTART.md                       # 5-minute setup guide
├── ARCHITECTURE.md                     # This file
├── .env.example                        # Configuration template
├── .gitignore                          # Git exclusions
├── app.py                              # Sample app to deploy
├── scripts/
│   ├── github-app-auth.sh             # Authentication
│   ├── create-deployment.sh           # Create deployment
│   ├── update-deployment-status.sh    # Update status
│   └── deploy-simulation.sh           # Full workflow
└── examples/
    └── deploy-example.sh              # Interactive example
```

## Future Enhancements

1. **Retry Logic**: Add exponential backoff for transient failures
2. **Webhooks**: Listen for GitHub events (on deployment status change)
3. **Auto-rollback**: Revert to previous deployment on failure
4. **Slack Integration**: Notify on deployment status changes
5. **Database**: Track deployment history
6. **Environment Parity**: Deploy to multiple environments in sequence
7. **Approval Gates**: Require manual approval before production deployments
8. **Artifact Management**: Track which artifacts were deployed
