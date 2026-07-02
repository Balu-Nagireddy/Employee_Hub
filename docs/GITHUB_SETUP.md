# GitHub Actions Setup Guide

## For Beginners — Complete Step-by-Step

This guide walks you through configuring **all** the secrets, variables, and settings needed to run the Employee Hub GitHub Actions automation pipeline.

---

## What Are GitHub Secrets and Variables?

### Secrets (🔒 Hidden)
- **Used for sensitive data** like passwords, API keys, tokens
- **Encrypted** — once saved, you can NEVER see the value again (only overwrite it)
- Accessed as `${{ secrets.SECRET_NAME }}` in workflows

### Variables (👁️ Visible)
- **Used for non-sensitive config** like region names, account IDs
- **Visible** to anyone with repo access
- Accessed as `${{ vars.VARIABLE_NAME }}` in workflows

---

## How Secrets Flow Through the System

Here's exactly how your AWS credentials travel from GitHub to the actual deployment:

```
YOU (in GitHub.com UI)
    │
    ├── Go to: Settings → Secrets and variables → Actions
    │
    ├── Add Secret:  AWS_ACCESS_KEY_ID = "AKIAYOURKEY..."
    ├── Add Secret:  AWS_SECRET_ACCESS_KEY = "wJalrXUtom..."
    │
    ▼
GitHub Encrypted Storage (secure vault)
    │
    ▼
Workflow (e.g., deploy.yml)
    │
    │   uses: ./.github/actions/aws-auth
    │   with:
    │     aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}     ◄── Fetched from vault
    │     aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}  ◄── Fetched from vault
    │
    ▼
Composite Action (aws-auth/action.yml)
    │
    │   inputs:
    │     aws-access-key-id:             ◄── Receives the value
    │     aws-secret-access-key:          ◄── Receives the value
    │
    ▼
    │   aws-actions/configure-aws-credentials@v4
    │   with:
    │     aws-access-key-id: ${{ inputs.aws-access-key-id }}       ◄── Passes to AWS CLI
    │     aws-secret-access-key: ${{ inputs.aws-secret-access-key }}
    │
    ▼
AWS CLI is now authenticated → Can run: aws ecr, aws ssm, terraform, etc.
```

**Key point:** You create secrets ONCE in GitHub UI. All workflows reference them automatically. You never type your AWS key in any code file.

---

## THE DEFINITIVE LIST: All Secrets and Variables

These are VERIFIED against ALL sources:
- Terraform (`variables.tf`)
- All 6 workflow files
- Docker Compose files
- Shell scripts

### Step 1: Configure GitHub Variables

Navigate to: **Your Repository → Settings → Secrets and variables → Actions → Variables**

Click **"New repository variable"** and add each of these:

| # | Variable Name | Source File(s) That Use It | Your Value (fill in) |
|---|--------------|---------------------------|---------------------|
| 1 | `AWS_REGION` | `docker-build.yml`, `deploy.yml`, `rollback.yml`, `terraform.yml`, `ci.yml` | `__________` (e.g., `ap-south-1`) |
| 2 | `AWS_ACCOUNT_ID` | `docker-build.yml`, `deploy.yml`, `rollback.yml` — **used to construct ECR registry URL:** `<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com` | `__________` (e.g., `123456789012`) |

**How to find your AWS Account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```

### Step 2: Configure GitHub Secrets

Navigate to: **Your Repository → Settings → Secrets and variables → Actions → Secrets**

Click **"New repository secret"** and add each of these:

#### AWS Credentials (used by ALL workflows)

| # | Secret Name | Source File(s) That Use It | Your Value (fill in) |
|---|-------------|---------------------------|---------------------|
| 1 | `AWS_ACCESS_KEY_ID` | `aws-auth/action.yml`, `ci-cd.yml` (disabled), `docker-build.yml`, `deploy.yml`, `rollback.yml`, `terraform.yml` | `__________` |
| 2 | `AWS_SECRET_ACCESS_KEY` | Same as above — passed to `aws-actions/configure-aws-credentials@v4` | `__________` |

**How to create an AWS Access Key:**
1. Go to AWS Console → IAM → Users → Create user (or use existing)
2. Attach these minimum policies:
   - `AmazonEC2FullAccess` (describe instances, SSM)
   - `AmazonEC2ContainerRegistryFullAccess` (ECR push/pull)
   - `AmazonSSMFullAccess` (Run Command)
   - `AdministratorAccess` (or for Terraform — best to scope down)
3. Create Access Key → **Copy both key and secret immediately** (shown once!)

> ⚠️ **WARNING:** AWS shows the secret key only **once** during creation. Save it immediately.

#### Database Credentials (used by Deploy & Rollback workflows + passed to EC2)

| # | Secret Name | Source File(s) That Use It | Your Value (fill in) |
|---|-------------|---------------------------|---------------------|
| 3 | `DB_HOST` | `deploy.yml` (SSM env vars), `rollback.yml` (SSM env vars), **docker-compose.prod.yml** (consumed on EC2) | `__________` (e.g., `employee-hub-db.xxxxxx.ap-south-1.rds.amazonaws.com`) |
| 4 | `DB_USER` | Same — `deploy.yml`, `rollback.yml` | `__________` (e.g., `employeehub`) |
| 5 | `DB_PASSWORD` | Same — `deploy.yml`, `rollback.yml` | `__________` (your RDS master password) |
| 6 | `DB_NAME` | Same — `deploy.yml`, `rollback.yml` | `__________` (default: `employee_db`) |

**How to find your RDS endpoint:**
```bash
aws rds describe-db-instances --query "DBInstances[0].Endpoint.Address" --output text
```

#### Terraform Variables (used by Terraform workflow)

| # | Secret Name | Source File(s) That Use It | Your Value (fill in) |
|---|-------------|---------------------------|---------------------|
| 7 | `TF_VAR_DB_USERNAME` | `terraform.yml` — passed as `-var="db_username=${{ secrets.TF_VAR_DB_USERNAME }}"` | `__________` (same as DB_USER) |
| 8 | `TF_VAR_DB_PASSWORD` | `terraform.yml` — passed as `-var="db_password=${{ secrets.TF_VAR_DB_PASSWORD }}"` | `__________` (same as DB_PASSWORD) |

### Step 3: Verify Your Configuration

After adding all secrets and variables, your GitHub Settings page should look like this:

```
Settings → Secrets and variables → Actions

VARIABLES:
  AWS_REGION        = ap-south-1
  AWS_ACCOUNT_ID    = 123456789012

SECRETS:
  AWS_ACCESS_KEY_ID     = AKIA********************
  AWS_SECRET_ACCESS_KEY = wJalr********************
  DB_HOST               = employee-hub-db.*******.amazonaws.com
  DB_USER               = employeehub
  DB_PASSWORD           = ************************
  DB_NAME               = employee_db
  TF_VAR_DB_USERNAME    = employeehub
  TF_VAR_DB_PASSWORD    = ************************
```

---

## Complete Secrets-to-Workflow Mapping

| Workflow | Secrets Used | Variables Used | AWS Auth Needed? |
|----------|-------------|----------------|-----------------|
| **CI** (`ci.yml`) | None | `AWS_REGION` (in env) | ❌ No |
| **Security** (`security.yml`) | None | None | ❌ No |
| **Docker Build** (`docker-build.yml`) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | `AWS_REGION`, `AWS_ACCOUNT_ID` | ✅ Yes (2 jobs) |
| **Deploy** (`deploy.yml`) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DB_HOST`, `DB_USER`, `DB_PASSWORD` | `AWS_REGION`, `AWS_ACCOUNT_ID` | ✅ Yes |
| **Rollback** (`rollback.yml`) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DB_HOST`, `DB_USER`, `DB_PASSWORD` | `AWS_REGION`, `AWS_ACCOUNT_ID` | ✅ Yes |
| **Terraform** (`terraform.yml`) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_VAR_DB_USERNAME`, `TF_VAR_DB_PASSWORD` | `AWS_REGION` | ✅ Yes (plan/apply jobs) |

---

## Triggering the Workflows

### Automatic Triggers

| Event | Workflows That Run |
|-------|-------------------|
| **Push to `github-actions`** | `ci.yml` → `security.yml` |
| **PR to `main`** | `ci.yml` → `security.yml` |
| **Merge to `main`** | `docker-build.yml` → `deploy.yml` |
| **Deploy health check fails** | `rollback.yml` (auto-triggered via repository_dispatch) |

### Manual Triggers (Actions Tab)

Go to **Actions → [Workflow Name] → Run workflow**:

- **CI** — Select any branch
- **Security** — Select any branch
- **Docker Build** — Select `main`, optional semver tag
- **Deploy** — Select `main`, optional image tag, skip health check option
- **Rollback** — Enter previous tag to roll back to
- **Terraform** — Choose `plan` or `apply`

---

## Understanding the aws-auth Action

The file `.github/actions/aws-auth/action.yml` is a **reusable composite action** — like a helper function.

**Its 3 inputs:**
1. `aws-region` ← receives value from `${{ vars.AWS_REGION }}` (Variable)
2. `aws-access-key-id` ← receives value from `${{ secrets.AWS_ACCESS_KEY_ID }}` (Secret)
3. `aws-secret-access-key` ← receives value from `${{ secrets.AWS_SECRET_ACCESS_KEY }}` (Secret)

**What it does:** Configures the AWS CLI so subsequent `aws` commands work.

**Why it needs inputs:** Composite actions in GitHub Actions CANNOT access `${{ secrets.* }}` directly — secrets must be passed as inputs from the calling workflow. This is a security feature.

---

## Quick Reference Card

### 2 Variables to add:
```
AWS_REGION        = _________
AWS_ACCOUNT_ID    = _________
```

### 8 Secrets to add:
```
AWS_ACCESS_KEY_ID      = _________
AWS_SECRET_ACCESS_KEY  = _________
DB_HOST                = _________
DB_USER                = _________
DB_PASSWORD            = _________
DB_NAME                = _________
TF_VAR_DB_USERNAME     = _________  (same as DB_USER)
TF_VAR_DB_PASSWORD     = _________  (same as DB_PASSWORD)
```



4. Definitive Secrets & Variables List
2 Variables (add in Settings → Variables):
┌────────────────┬───────────────────────────────────────────┬─────────────────────────┐
│ Variable       │ Used By                                   │ Description             │
├────────────────┼───────────────────────────────────────────┼─────────────────────────┤
│ AWS_REGION     │ docker-build, deploy, rollback, terraform │ e.g., ap-south-1        │
│ AWS_ACCOUNT_ID │ docker-build, deploy, rollback            │ 12-digit AWS account ID │
└────────────────┴───────────────────────────────────────────┴─────────────────────────┘
8 Secrets (add in Settings → Secrets):
┌───────────────────────┬───────────────────────────────────────────┬──────────────────────────────────────┐
│ Secret                │ Used By                                   │ Description                          │
├───────────────────────┼───────────────────────────────────────────┼──────────────────────────────────────┤
│ AWS_ACCESS_KEY_ID     │ docker-build, deploy, rollback, terraform │ From IAM user                        │
│ AWS_SECRET_ACCESS_KEY │ docker-build, deploy, rollback, terraform │ From IAM user                        │
│ DB_HOST               │ deploy, rollback                          │ RDS endpoint hostname                │
│ DB_USER               │ deploy, rollback                          │ RDS master username                  │
│ DB_PASSWORD           │ deploy, rollback                          │ RDS master password                  │
│ DB_NAME               │ deploy, rollback                          │ Database name (default: employee_db) │
│ TF_VAR_DB_USERNAME    │ terraform only                            │ Same as DB_USER                      │
│ TF_VAR_DB_PASSWORD    │ terraform only                            │ Same as DB_PASSWORD                  │
└───────────────────────┴───────────────────────────────────────────┴──────────────────────────────────────┘
All fully documented in  docs/GITHUB_SETUP.md  with fill-in-the-blank tables.
5. The Complete Automation Flow
Here's exactly how the entire pipeline works from code to production:
YOU (developer)
    │
    │ 1. Write code on 'github-actions' branch
    │
    ├── git push origin github-actions
    │       │
    │       ▼
    │   CI (ci.yml) RUNS AUTOMATICALLY
    │   ├── Terraform fmt/validate
    │   ├── Python lint + tests
    │   ├── TypeScript check + build
    │   └── Docker compose validate + build test
    │       │
    │       ▼
    │   Security (security.yml) RUNS AUTOMATICALLY after CI
    │   ├── Trivy filesystem scan
    │   ├── Trivy Docker image scans (3 images)
    │   ├── Trivy dependency scans (Python + Node)
    │   ├── Trivy secret scan + license scan
    │   └── SARIF uploaded to GitHub Security tab
    │
    ├── Create Pull Request: github-actions → main
    │       │
    │       ▼
    │   CI RUNS AGAIN on the PR
    │   Security RUNS AGAIN after CI
    │   (PR shows ✅/❌ status checks)
    │       │
    │       ▼
    │   ✅ All checks pass → Merge button turns green
    │
    ├── Click "Merge pull request" to main
    │       │
    │       ▼
    │   Docker Build (docker-build.yml) RUNS AUTOMATICALLY
    │   ├── Creates ECR repos if missing
    │   ├── Builds 3 images (api, frontend, gateway)
    │   └── Pushes to Amazon ECR with tags: latest, SHA, branch
    │       │
    │       ▼
    │   Deploy (deploy.yml) RUNS AUTOMATICALLY after Docker Build
    │   ├── Authenticates via SSM (no SSH!)
    │   ├── Finds EC2 instance
    │   ├── Uploads config files (Compose + monitoring)
    │   ├── Pulls latest images from ECR
    │   ├── Restarts Docker Compose
    │   └── Runs health checks on ALL 6 services
    │       │
    │       ┌──────────────────┴──────────────────┐
    │       │                                     │
    │   ✅ All healthy                       ❌ Service fails
    │       │                                     │
    │  DEPLOY COMPLETE                   Rollback (rollback.yml)
    │                                         RUNS AUTOMATICALLY
    │                                     ├── Redeploys previous tag
    │                                     └── Verifies health
    │
    └── Application is LIVE at http://<ec2-ip>
6. To Automate Merging (Optional Next Step)
If you want PR merges to be fully automated (no manual click):
1. Branch protection rules on  main :
- Settings → Branches → Add rule for  main 
- ✅ Require PR before merging
- ✅ Require status checks:  CI / CI Summary ,  Security / Trivy Security Scan 
- ✅ Dismiss stale reviews
- ✅ Require branches up to date
2. Auto-merge (GitHub's built-in):
- After protection rules pass, GitHub can auto-merge the PR
- Set it as a repo setting:  Allow auto-merge 
3. No manual click needed: Developer just creates PR → CI/Security pass → GitHub auto-merges → Deployment flows automatically