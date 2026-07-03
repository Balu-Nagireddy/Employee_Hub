# Deployment Guide

## Overview

The Employee Hub application is deployed to a single EC2 instance using **AWS Systems Manager Run Command**. All deployments are automated through **GitHub Actions** — no manual SSH access is required.

## Deployment Flow

```
GitHub Actions ──▶ Merge to main
                       │
                       ▼
               Docker Build (ECR)
                       │
                       ▼
               SSM Run Command
                       │
                       ▼
               EC2 Instance
                       │
                       ▼
             Pull latest images
                       │
                       ▼
             Restart Compose stack
                       │
                       ▼
             Health Check (all services)
                       │
                       ▼
            ┌──────────┴──────────┐
        ✅ Pass              ❌ Fail
            │                       │
      Deployment            Auto-rollback
      Complete              to previous version
```

## Prerequisites

1. **GitHub Repository** — `Employee_Hub` with the GitHub Actions workflows
2. **AWS Infrastructure** — Provisioned via Terraform (see `terraform/`)
3. **EC2 Instance** — Running Amazon Linux 2023 with:
   - Docker and Docker Compose installed
   - SSM Agent running
   - IAM role with `AmazonSSMManagedInstanceCore`
4. **Amazon ECR Repositories** — Created automatically by `docker-build.yml`
5. **GitHub Secrets** — Configured (see below)

## GitHub Secrets Configuration

Navigate to: **Settings → Secrets and variables → Actions → Secrets**

| Secret | Description | Example |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `DB_HOST` | RDS endpoint (hostname only) | `employee-hub-db.xxxxxx.ap-south-1.rds.amazonaws.com` |
| `DB_PORT` | RDS port | `5432` |
| `DB_USER` | RDS master username | `employeehub` |
| `DB_PASS` | RDS master password | `YourSecurePassword123!` |
| `DB_NAME` | RDS database name | `employee_db` |
| `TF_VAR_DB_USERNAME` | Same as DB_USER (for Terraform) | `employeehub` |
| `TF_VAR_DB_PASSWORD` | Same as DB_PASS (for Terraform) | `YourSecurePassword123!` |

## GitHub Variables Configuration

Navigate to: **Settings → Secrets and variables → Actions → Variables**

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `ap-south-1` |
| `AWS_ACCOUNT_ID` | AWS account ID (numeric) | `123456789012` |

## Deployment Methods

### 1. Automatic (Merge to `main`)

1. Create a PR from `github-actions` to `main`
2. CI and Security workflows run automatically
3. Merge the PR
4. Docker Build workflow builds and pushes images to ECR
5. Deploy workflow deploys to EC2 via SSM
6. Health check verifies all services

### 2. Manual (workflow_dispatch)

1. Go to **Actions → Docker Build → Run workflow**
2. Select `main` branch
3. Optionally specify a semantic version tag
4. After Docker Build completes, go to **Actions → Deploy → Run workflow**
5. Optionally specify a custom image tag or skip health checks

## Deployed Services

After deployment, the following services are available:

| Service | Port | URL |
|---------|------|-----|
| Frontend (Nginx) | 80 | `http://<ec2-ip>` |
| KrakenD Gateway | 8080 | `http://<ec2-ip>:8080` |
| Employee API | — | Internal (via gateway) |
| Prometheus | 9090 | `http://<ec2-ip>:9090` |
| Grafana | 3001 | `http://<ec2-ip>:3001` |
| Loki | 3100 | Internal |
| PostgreSQL (RDS) | 5432 | Private (EC2 only) |

## Health Checks

The deploy workflow automatically verifies:
- Employee API (port 8000) — `/health`
- KrakenD Gateway (port 8080) — `/health`
- Frontend (port 80) — `/`
- Prometheus (port 9090) — `/-/healthy`
- Grafana (port 3001) — `/api/health`
- Loki (port 3100) — `/ready`

## Troubleshooting

### Deployment fails at health check

The workflow automatically triggers a rollback. The rollback redeploys the previous image version.

### SSM command fails

1. Verify the EC2 instance is running: `aws ec2 describe-instances --filters ...`
2. Verify SSM Agent is running on EC2: `sudo systemctl status amazon-ssm-agent`
3. Verify IAM role has `AmazonSSMManagedInstanceCore` policy
4. Check the deploy log on EC2: `/var/log/employee-hub-deploy.log`

### Docker Compose fails to start

1. Check Docker Compose logs: `docker compose -f /opt/employee-hub/deployments/docker/docker-compose.prod.yml logs`
2. Verify environment variables are set: `cat /opt/employee-hub/.env`
3. Check disk space: `df -h`

### Container keeps restarting

1. Check container logs: `docker logs <container-name>`
2. Verify RDS connectivity: `timeout 5 bash -c "</dev/tcp/${DB_HOST}/${DB_PORT}"`
3. Check Docker Compose status: `docker compose -f /opt/employee-hub/deployments/docker/docker-compose.prod.yml ps`
