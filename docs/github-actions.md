# GitHub Actions Design

## Architecture Principles

The Employee Hub GitHub Actions architecture follows these principles:

1. **Single Responsibility** — Each workflow has one job type
2. **Modular** — Workflows are independent, reusable composite actions reduce duplication
3. **Fail Fast** — Critical checks fail early in the pipeline
4. **Secure** — Secrets are never hardcoded; least-privilege IAM
5. **Observable** — Every workflow prints timestamps, Git SHA, duration, and summary
6. **Performant** — Caching, concurrency, and parallel jobs minimize execution time

## File Structure

```
.github/
├── workflows/
│   ├── ci.yml              # Continuous Integration
│   ├── security.yml        # Security scanning
│   ├── docker-build.yml    # Amazon ECR build & push
│   ├── deploy.yml          # SSM deployment
│   ├── rollback.yml        # Automated rollback
│   └── terraform.yml       # Terraform IaC
├── actions/
│   ├── setup-python/
│   │   └── action.yml      # Reusable Python setup + caching
│   ├── setup-node/
│   │   └── action.yml      # Reusable Node.js setup + caching
│   └── aws-auth/
│       └── action.yml      # Reusable AWS authentication
└── scripts/
    ├── deploy.sh           # Remote deploy script (runs on EC2)
    ├── rollback.sh         # Remote rollback script (runs on EC2)
    └── health-check.sh     # Remote health check script (runs on EC2)
```

## Composite Actions

### `setup-python`

Reusable action that:
- Installs the specified Python version
- Caches pip dependencies based on `requirements.txt` hash
- Installs project dependencies on cache miss

| Input | Default | Description |
|-------|---------|-------------|
| `python-version` | `3.12` | Python version |
| `working-directory` | `services/employee-api` | Directory with `requirements.txt` |
| `cache-key-prefix` | `pip` | Cache key prefix |

### `setup-node`

Reusable action that:
- Installs the specified Node.js version
- Caches `node_modules` based on `package-lock.json` hash
- Runs `npm ci` on cache miss

| Input | Default | Description |
|-------|---------|-------------|
| `node-version` | `20` | Node.js version |
| `working-directory` | `services/frontend` | Directory with `package.json` |
| `cache-key-prefix` | `npm` | Cache key prefix |

### `aws-auth`

Reusable action that:
- Configures AWS credentials via `aws-actions/configure-aws-credentials`
- Verifies the authenticated identity

| Input | Required | Description |
|-------|----------|-------------|
| `aws-region` | No (default: `ap-south-1`) | AWS region |
| `aws-access-key-id` | **Yes** | Pass `${{ secrets.AWS_ACCESS_KEY_ID }}` |
| `aws-secret-access-key` | **Yes** | Pass `${{ secrets.AWS_SECRET_ACCESS_KEY }}` |

> **Note:** Composite actions cannot access `${{ secrets.* }}` directly. Secrets must be passed as inputs from the calling workflow.

## Concurrency Strategy

| Workflow | Group Key | Cancel in Progress |
|----------|-----------|-------------------|
| CI | `ci-${{ github.ref }}` | Yes |
| Security | `security-${{ github.ref }}` | Yes |
| Docker Build | `docker-build-${{ github.ref }}` | Yes |
| Deploy | `deploy-${{ github.ref }}` | No |
| Rollback | `rollback-${{ github.ref }}` | No |
| Terraform | `terraform-${{ github.ref }}` | Yes |

Deploy and Rollback use `cancel-in-progress: false` to prevent cancellation of critical deployment operations.

## Caching Strategy

| Cache | Key | Scope | Used In |
|-------|-----|-------|---------|
| pip packages | `pip-${{ runner.os }}-${{ pythonLocation }}-${{ hashFiles('requirements.txt') }}` | Per environment | CI, Security |
| node_modules | `npm-${{ runner.os }}-${{ hashFiles('package-lock.json') }}` | Per runner OS | CI, Security |
| Terraform providers | `tf-${{ runner.os }}-${{ hashFiles('.terraform.lock.hcl') }}` | Per runner OS | CI, Terraform |
| Docker layers | `type=gha,scope=<service>` | Per service | Docker Build |

## Logging Standards

Every workflow includes:
- **Timestamps** — Via `date -u` in shell steps and `$(date)` in scripts
- **Execution duration** — Calculated with `date +%s` before/after
- **Git SHA** — Printed as `${{ github.sha }}`
- **Workflow summary** — Via `$GITHUB_STEP_SUMMARY` with markdown tables
- **Artifacts** — Test results, plan outputs, SARIF reports saved with retention policies

## Security Considerations

1. **Secrets** — All sensitive values stored in GitHub Secrets, never hardcoded
2. **Variables** — Non-sensitive configuration stored in GitHub Variables
3. **IAM** — AWS credentials scoped to minimum required permissions
4. **SARIF** — Security findings uploaded to GitHub Security tab
5. **SSM** — Deployment uses SSM Run Command; no SSH keys stored in CI
6. **Permissions** — Each workflow uses minimal `permissions:` block

## GitHub Environments

| Environment | Used By | Protection Rules |
|-------------|---------|-----------------|
| `production` | Terraform apply | Required reviewers, manual approval |

The `production` environment is used for Terraform apply to require manual approval before infrastructure changes.

## Branch Protection Rules (Recommended)

Configure these branch protection rules on `main`:

| Rule | Value |
|------|-------|
| Require PR before merge | ✅ |
| Require status checks | `CI / CI Summary` |
| Require branches up to date | ✅ |
| Include administrators | ✅ |
| Allow force pushes | ❌ |
| Allow deletions | ❌ |
