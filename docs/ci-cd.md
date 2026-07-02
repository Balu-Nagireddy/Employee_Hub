# CI/CD Pipeline

## Overview

The Employee Hub uses a modular **GitHub Actions** architecture with six independent workflows. Each workflow has a single responsibility and is triggered by specific events.

```
Developer ──▶ github-actions ──▶ Push ──▶ CI ──▶ PR ──▶ Merge ──▶ main ──▶ CD
```

## Workflow Dependency Graph

```
                    ┌──────────┐
                    │   Push   │
                    │github-act│
                    └────┬─────┘
                         │
                    ┌────▼─────┐   ┌──────────┐
                    │    CI    │   │ PR to main│
                    │          │   └────┬─────┘
                    └────┬─────┘       │
                         │             │
                    ┌────▼─────┐       │
                    │ Security  │       │
                    │           │       │
                    └────┬─────┘       │
                         │             │
                ┌────────▼────────┐    │
                │  Merge to main  │◄───┘
                └────────┬────────┘
                         │
                 ┌───────▼────────┐
                 │   Docker Build │
                 │ (Amazon ECR)   │
                 └───────┬────────┘
                         │
                 ┌───────▼────────┐
                 │     Deploy     │
                 │ (SSM Run Cmd)  │
                 └───────┬────────┘
                         │
                ┌────────▼────────┐
                │  Rollback (if   │
                │    fails)       │
                └─────────────────┘

  Terraform (manual trigger via workflow_dispatch)
  ┌──────────────────────────────────────────┐
  │  fmt → validate → plan → apply (manual) │
  └──────────────────────────────────────────┘
```

## Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI** | `ci.yml` | Push to `github-actions`, PR to `main` | Code quality, tests, Docker validation |
| **Security** | `security.yml` | After CI succeeds, manual | Vulnerability scanning, SARIF upload |
| **Docker Build** | `docker-build.yml` | Push to `main`, manual | Build & push to Amazon ECR |
| **Deploy** | `deploy.yml` | After Docker Build, manual | SSM-based deployment to EC2 |
| **Rollback** | `rollback.yml` | Repository dispatch, manual | Automated rollback to previous version |
| **Terraform** | `terraform.yml` | Push/PR to Terraform dirs, manual | Infrastructure as Code management |

## CI Workflow (`ci.yml`)

**Triggers:** Push to `github-actions`, PR to `main`

**Parallel Jobs:**

| Job | Tools | Purpose |
|-----|-------|---------|
| `terraform-checks` | `terraform fmt`, `terraform validate` | Infrastructure code quality |
| `backend` | Python lint (flake8, black), pytest | Backend quality & correctness |
| `frontend` | TypeScript check, Vite build | Frontend quality & correctness |
| `docker-validation` | Compose config, Docker build (no push) | Container build validation |

**Features:**
- Concurrency groups with `cancel-in-progress`
- Dependency caching (pip, npm, Terraform providers)
- JUnit test reports as artifacts
- Frontend build artifacts
- Terraform plan on PRs (uploaded as artifact)
- Workflow summary with status for each job

## Security Workflow (`security.yml`)

**Triggers:** After CI completes successfully, manual

**Scans (all via Trivy):**

| Scan Type | Target | SARIF Category |
|-----------|--------|---------------|
| Filesystem | Full repository | `filesystem` |
| Docker Images | employee-api, frontend, gateway | `docker-image-*` |
| Python Dependencies | services/employee-api | `python-dependencies` |
| Node.js Dependencies | services/frontend | `node-dependencies` |
| Secrets | Full repository | `secrets` |
| Licenses | Full repository | `licenses` |

**Features:**
- All SARIF reports uploaded to GitHub Security tab
- Fails on CRITICAL and HIGH severity findings
- Reports saved as workflow artifacts (30-day retention)
- Builds Docker images locally for scanning

## Docker Build Workflow (`docker-build.yml`)

**Triggers:** Push to `main`, manual

**Registry:** Amazon ECR

**Tags per image:**
- `latest`
- Git commit SHA
- Branch name
- Semantic version (if git tag matches `v#.#.#`)

**Services built:**
- `employee-api` — Python FastAPI
- `frontend` — React + Vite + TypeScript
- `gateway` — KrakenD API Gateway

**Features:**
- Automatic ECR repository creation if missing
- Docker layer caching via GitHub Cache (type: gha)
- Matrix build (all services in parallel)

## Deploy Workflow (`deploy.yml`)

**Triggers:** After Docker Build succeeds, manual

**Method:** AWS Systems Manager Run Command (no SSH)

**Steps:**
1. Authenticate to AWS
2. Find the EC2 instance by tag
3. Package deployment configs (Docker Compose, monitoring configs, scripts)
4. Build remote deploy script with embedded config
5. Send script to EC2 via SSM Run Command
6. Wait for deployment to settle
7. Run health check via SSM (all services)
8. Auto-trigger rollback if health check fails

**Secrets required:**
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`

## Rollback Workflow (`rollback.yml`)

**Triggers:** Repository dispatch from deploy, manual

**Steps:**
1. Authenticate to AWS
2. Find EC2 instance
3. Determine previous image tag (from `.previous-tag` on EC2 or manual input)
4. Build and send rollback script via SSM
5. Verify rollback health
6. Fail workflow if rollback fails

## Terraform Workflow (`terraform.yml`)

**Triggers:** Push/PR to Terraform dirs, manual (`workflow_dispatch`)

**Actions:**

| Action | Trigger | Description |
|--------|---------|-------------|
| `fmt` | Push to `github-actions`, PR | Check Terraform formatting |
| `validate` | Push to `github-actions`, PR | Validate configuration |
| `plan` | PR, manual | Generate execution plan |
| `apply` | Manual only | Apply infrastructure changes |

**Features:**
- Terraform provider caching
- Plan posted as PR comment
- Plan saved as workflow artifact
- Manual apply requires explicit `workflow_dispatch` with `action: apply`
- Sensitive variables passed via GitHub Secrets

## Required Secrets

| Secret | Description | Used By |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | All workflows |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | All workflows |
| `DB_HOST` | RDS PostgreSQL endpoint | Deploy, Rollback |
| `DB_USER` | RDS master username | Deploy, Rollback |
| `DB_PASS` | RDS master password | Deploy, Rollback |
| `TF_VAR_DB_USERNAME` | Terraform DB username | Terraform |
| `TF_VAR_DB_PASSWORD` | Terraform DB password | Terraform |

## Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `ap-south-1` |
| `AWS_ACCOUNT_ID` | AWS account ID | (required for ECR) |
