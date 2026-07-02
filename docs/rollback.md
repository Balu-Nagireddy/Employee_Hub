# Rollback Process

## Overview

The rollback process is an automated safety net for the Employee Hub deployment pipeline. If a deployment fails health checks, the rollback workflow automatically redeploys the **last known good image version**.

## Trigger Mechanisms

### Automatic (from Deploy)

If the deploy workflow's health check step detects any service failure, it:

1. Sets `HEALTH_CHECK_FAILED=true`
2. Prints failure details to the workflow log
3. Generates a repository dispatch event
4. Fails the deploy workflow

### Manual (workflow_dispatch)

1. Go to **Actions → Rollback → Run workflow**
2. Select `main` branch
3. Enter the **previous-tag** (image tag to roll back to)
4. Optionally specify an **instance-id** (auto-detected if omitted)

## Rollback Sequence

```
Health Check Failure
         │
         ▼
Trigger Rollback (repository_dispatch)
         │
         ▼
Find EC2 Instance
         │
         ▼
Determine Previous Tag
  ├── From deploy payload
  └── From EC2 (.previous-tag file)
         │
         ▼
Build Rollback Script
         │
         ▼
Send via SSM Run Command
         │
         ▼
EC2 Executes:
  ├── Login to ECR
  ├── Pull previous images
  ├── Restart Docker Compose
  └── Verify containers
         │
         ▼
Health Check (post-rollback)
         │
    ┌────┴────┐
  ✅ Pass   ❌ Fail
    │           │
  Rollback    Workflow Fails
  Complete    ─ manual intervention
```

## Tag Management

The EC2 instance maintains tag state files in `/opt/employee-hub/`:

| File | Purpose |
|------|---------|
| `.current-tag` | The currently deployed image tag |
| `.previous-tag` | The previously deployed image tag (for rollback) |

These files are updated automatically during each deployment.

## Rollback Script

The rollback script (`rollback.yml`) runs on the EC2 instance via SSM:

1. **Authenticate** to Amazon ECR
2. **Pull** images with the previous tag
3. **Restart** Docker Compose with `--remove-orphans`
4. **Verify** running containers
5. **Log** all output to `/var/log/employee-hub-rollback.log`

## Failure Scenarios

### Previous tag not found

If no previous tag is available:
- Automatic rollback will attempt to read `.previous-tag` from EC2
- If the file doesn't exist, the rollback fails
- Manual intervention: specify the tag via `workflow_dispatch`

### SSM command fails

- The rollback workflow reports the SSM Status
- Check SSM logs: `aws ssm get-command-invocation --command-id <id> --instance-id <id>`
- Check EC2 logs: `/var/log/employee-hub-rollback.log`

### Docker Compose fails to start with previous images

- The rollback workflow reports failure
- Manual intervention required:
  1. SSH/SSM into EC2
  2. Inspect Docker logs: `docker compose -f /opt/employee-hub/deployments/docker/docker-compose.prod.yml logs`
  3. Manually deploy a known-good version

## Rollback Logs

All rollback output is logged to:
- **EC2:** `/var/log/employee-hub-rollback.log`
- **GitHub Actions:** Workflow run logs (saved as artifacts if configured)

## Best Practices

1. **Never delete old ECR images** — Keep at least the last 5 tags for rollback safety
2. **Test rollback manually** — Run the rollback workflow in a staging environment first
3. **Monitor rollback frequency** — Frequent rollbacks indicate underlying issues
4. **Document rollback procedures** — Keep this documentation up to date
