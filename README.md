# Employee Hub

A production-ready DevOps showcase project demonstrating **Infrastructure as Code**, **API Gateway Architecture**, **Containerization**, **Monitoring**, **Logging**, and **CI/CD** best practices — all within **AWS Free Tier**.

Built with **FastAPI**, **React**, **KrakenD**, **PostgreSQL**, **Prometheus**, **Grafana**, **Loki**, and **Docker Compose** on a single EC2 instance.

---

## Architecture

```
Browser ──▶ Nginx ──▶ KrakenD Gateway ──▶ FastAPI Backend ──▶ RDS PostgreSQL
             │           │                      │
             │     ┌─────┴─────┐                │
             │     │ Monitoring │                │
             │     │ Prometheus │                │
             │     │  Grafana   │                │
             │     │   Loki     │                │
             └─────┴── Promtail ┘────────────────┘
```

### Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| **API Gateway** | KrakenD (self-hosted) | ALB costs $20+/month; KrakenD runs on the same EC2 at no extra cost |
| **Orchestration** | Docker Compose | ECS Fargate costs $30+/month; single-node deployment doesn't need it |
| **Compute** | 1x EC2 t3.micro | Free Tier eligible ($8.47/month normally); 6 containers fit comfortably |
| **NAT Gateway** | None | $35+/month saved; RDS in private subnets doesn't need outbound internet |
| **Database** | RDS in private subnets | Industry best practice; only accessible from EC2 security group |
| **Logging** | Loki + Promtail | CloudWatch Logs costs $0.50/GB ingested; Loki on EC2 is free |

For full architectural rationale, see [Architecture Decision Records](docs/architecture.md).

## Infrastructure

| Resource | Type | Purpose |
|----------|------|---------|
| VPC | 10.0.0.0/16 | Isolated network with public + private subnets |
| EC2 | t3.micro (Free Tier) | Hosts all Docker containers |
| RDS | db.t3.micro (Free Tier) | Managed PostgreSQL 16 |
| S3 | Standard | Terraform state backend (versioned, encrypted) |
| DynamoDB | PAY_PER_REQUEST | Terraform state locking |
| IAM | SSM ManagedInstanceCore | EC2 access via Session Manager |

See [Terraform documentation](terraform/) for full infrastructure details.

## Folder Structure

```
Employee_Hub/
├── .github/
│   ├── workflows/             # Modular GitHub Actions pipeline
│   │   ├── ci.yml             # Continuous Integration
│   │   ├── security.yml       # Security scanning (Trivy + SARIF)
│   │   ├── docker-build.yml   # Amazon ECR build & push
│   │   ├── deploy.yml         # SSM-based deployment to EC2
│   │   ├── rollback.yml       # Automated rollback
│   │   └── terraform.yml      # Terraform IaC workflow
│   ├── actions/               # Reusable composite actions
│   │   ├── setup-python/      # Python setup + caching
│   │   ├── setup-node/        # Node.js setup + caching
│   │   └── aws-auth/          # AWS authentication
│   └── scripts/               # Deployment scripts (SSM)
│       ├── deploy.sh
│       ├── rollback.sh
│       └── health-check.sh
├── services/
│   ├── employee-api/          # Python FastAPI backend
│   │   ├── app/
│   │   │   ├── api/routes/    # API endpoints
│   │   │   ├── middleware/    # Logging middleware
│   │   │   ├── models/        # SQLAlchemy models
│   │   │   ├── repositories/  # Data access layer
│   │   │   ├── schemas/       # Pydantic models
│   │   │   ├── services/      # Business logic
│   │   │   └── monitoring/    # Prometheus metrics
│   │   ├── alembic/           # Database migrations
│   │   └── tests/             # Pytest test suite
│   ├── frontend/              # React + Vite + TypeScript
│   │   └── src/               # App source code
│   └── gateway/               # KrakenD API Gateway
├── terraform/                 # AWS Infrastructure as Code
│   ├── main.tf                # All AWS resources
│   ├── variables.tf           # Configurable variables
│   ├── outputs.tf             # Resource outputs
│   ├── backend.tf             # Terraform backend config
│   └── user_data.sh           # EC2 bootstrap script
├── monitoring/                # Prometheus, Grafana, Loki configs
│   ├── prometheus/
│   ├── grafana/
│   │   └── dashboards/        # Pre-built dashboards
│   ├── loki/
│   └── promtail/
├── deployments/               # Production Docker Compose & scripts
├── common/                    # Shared configs, SQL, Postman
├── docs/
│   ├── architecture.md        # Architecture + ADRs
│   ├── ci-cd.md               # CI/CD pipeline documentation
│   ├── deployment.md          # Deployment guide
│   ├── github-actions.md      # Workflow design docs
│   ├── rollback.md            # Rollback process
│   └── legacy/                # Archived original workflow
├── docker-compose.yml         # Development environment
├── Makefile                   # Convenience commands
└── README.md                  # This file
```

## Technology Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Backend** | Python 3.12, FastAPI | Employee CRUD API |
| **Frontend** | React 18, Vite, TypeScript | User interface |
| **Gateway** | KrakenD 2.7 | API Gateway, routing, CORS |
| **Database** | PostgreSQL 16 (RDS) | Managed data persistence |
| **ORM** | SQLAlchemy 2.0 | Database interaction |
| **Migrations** | Alembic | Schema versioning |
| **Validation** | Pydantic 2 | Data validation |
| **Containerization** | Docker, Docker Compose | Container management |
| **Monitoring** | Prometheus + Grafana | Metrics & dashboards |
| **Logging** | Loki + Promtail | Log aggregation |
| **Infrastructure** | Terraform | AWS provisioning (IaC) |
| **CI/CD** | GitHub Actions | Automation pipeline |
| **Testing** | Pytest | Backend tests |

## Application Flow

```
1. Browser ──▶ Nginx (port 80)      ──▶ Serves React SPA
2. Nginx    ──▶ KrakenD (port 8080) ──▶ Proxies /api/* requests
3. KrakenD  ──▶ FastAPI (port 8000) ──▶ Routes to backend
4. FastAPI  ──▶ RDS (port 5432)     ──▶ Queries PostgreSQL
5. All external requests go through KrakenD only
6. Backend is never exposed directly to clients
```

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/employees` | List all employees |
| GET | `/api/employees/{id}` | Get employee by ID |
| POST | `/api/employees` | Create new employee |
| PUT | `/api/employees/{id}` | Update employee |
| DELETE | `/api/employees/{id}` | Delete employee |
| GET | `/api/health` | Health check |
| GET | `/api/ready` | Readiness check |
| GET | `/api/live` | Liveness check |

### API Documentation

- **Swagger UI**: `http://<ec2-ip>:8080/docs` (via Gateway) or `http://<ec2-ip>:8000/docs`
- **Postman Collection**: `common/postman/Employee_Hub.postman_collection.json`

## Database Schema

```sql
CREATE TABLE employees (
    id              SERIAL PRIMARY KEY,
    employee_code   VARCHAR(20) UNIQUE NOT NULL,
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    department      VARCHAR(50) NOT NULL,
    designation     VARCHAR(100) NOT NULL,
    salary          FLOAT NOT NULL,
    status          VARCHAR(20) DEFAULT 'active',
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Make (optional)
- Node.js 20+ (for local frontend dev)
- Python 3.12+ (for local backend dev)
- AWS CLI (for deployment)
- Terraform >= 1.6 (for infrastructure)

### Local Development (One Command)

```bash
git clone https://github.com/your-org/Employee_Hub.git
cd Employee_Hub

# Start all services (development mode — uses local Docker builds)
docker compose up -d

# Check status
docker compose ps
```

### Local Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | - |
| **API Gateway** | http://localhost:8080 | - |
| **FastAPI Docs** | http://localhost:8000/docs | - |
| **Prometheus** | http://localhost:9090 | - |
| **Grafana** | http://localhost:3001 | admin / admin |
| **PostgreSQL** | localhost:5432 | employee_user / employee_pass |

### Makefile Commands

```bash
make up       # Start all services
make down     # Stop all services
make build    # Build all Docker images
make logs     # View logs
make ps       # List running services
make test     # Run backend tests
make seed     # Seed database with sample data
make health   # Check health of all services
make clean    # Remove all containers and volumes
```

## AWS Deployment

### 1. Deploy Infrastructure (Terraform)

```bash
cd terraform

# Initialize (first time with local state to bootstrap S3/DynamoDB)
terraform init
terraform apply -target=aws_s3_bucket.terraform_state \
                -target=aws_dynamodb_table.terraform_lock

# Uncomment backend block in backend.tf, then:
terraform init -migrate

# Deploy all infrastructure
terraform plan \
  -var="db_username=employeehub" \
  -var="db_password=admin"

terraform apply \
  -var="db_username=employeehub" \
  -var="db_password=admin"
```

### 2. View Outputs

```bash
terraform output ec2_public_ip
terraform output frontend_url
terraform output gateway_url
terraform output grafana_url
terraform output prometheus_url
terraform output ssh_command
```

### 3. Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ap-south-1` | AWS region |
| `instance_type` | `t3.micro` | EC2 instance type |
| `allowed_ssh_cidr` | `["0.0.0.0/0"]` | SSH access — **restrict in production** |
| `grafana_allowed_cidr` | `["0.0.0.0/0"]` | Grafana access — **restrict in production** |
| `prometheus_allowed_cidr` | `["0.0.0.0/0"]` | Prometheus access — **restrict in production** |
| `db_username` | _(required)_ | RDS master username |
| `db_password` | _(required)_ | RDS master password (min 16 chars, upper+lower+digit) |
| `db_name` | `employee_db` | RDS database name |
| `key_pair_name` | `null` | EC2 key pair name (null = use SSM) |

### Terraform Outputs

| Output | Description |
|--------|-------------|
| `ec2_public_ip` | EC2 public IP address |
| `frontend_url` | Frontend URL (port 80) |
| `gateway_url` | KrakenD Gateway URL (port 8080) |
| `grafana_url` | Grafana URL (port 3001) |
| `prometheus_url` | Prometheus URL (port 9090) |
| `db_endpoint` | RDS PostgreSQL endpoint |
| `ssh_command` | SSH / SSM connection command |

## CI/CD Pipeline

The project uses a **modular GitHub Actions** architecture with 6 independent workflows. Deployment happens exclusively through GitHub Actions — no manual SSH is required.

### Workflow Dependency Graph

```
Developer
    │
    ▼
github-actions branch
    │
    ├── Push ──▶ CI (ci.yml)
    │                   │
    │                   ▼
    │              Security (security.yml)
    │
    ├── PR to main ──▶ CI (ci.yml)
    │
    └── Merge to main ──▶ Docker Build (docker-build.yml) ──▶ Deploy (deploy.yml)
                                                                       │
                                                                  ┌─────┴─────┐
                                                              ✅ Pass    ❌ Fail
                                                                              │
                                                                         Rollback (rollback.yml)
```

| Workflow | File | Description |
|----------|------|-------------|
| **CI** | `ci.yml` | Terraform fmt/validate, Python lint/tests, TypeScript check/build, Docker validation — runs in parallel |
| **Security** | `security.yml` | Trivy filesystem, Docker image, dependency, secret, and license scans with SARIF upload to GitHub Security tab |
| **Docker Build** | `docker-build.yml` | Build & push images to **Amazon ECR** with tags: `latest`, git SHA, branch, semver |
| **Deploy** | `deploy.yml` | SSM Run Command deployment to EC2 — uploads configs, pulls images, restarts stack, verifies health |
| **Rollback** | `rollback.yml` | Automatic rollback to previous image version on health check failure |
| **Terraform** | `terraform.yml` | IaC workflow: `fmt` → `validate` → `plan` → manual `apply` |

### Required Secrets

| Secret | Description | Used By |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key | All workflows |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | All workflows |
| `DB_HOST` | RDS endpoint | Deploy, Rollback |
| `DB_USER` | RDS master username | Deploy, Rollback |
| `DB_PASSWORD` | RDS master password | Deploy, Rollback |
| `TF_VAR_DB_USERNAME` | Terraform DB username | Terraform |
| `TF_VAR_DB_PASSWORD` | Terraform DB password | Terraform |

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `ap-south-1` |
| `AWS_ACCOUNT_ID` | AWS account ID (for ECR) | (required) |

### Key Features

- **No SSH** — All deployment via AWS SSM Run Command
- **Amazon ECR** — Container registry (not GHCR)
- **Concurrency** — Stale runs cancelled automatically
- **Caching** — pip, npm, Terraform providers, Docker layers
- **Logging** — Timestamps, duration, Git SHA, workflow summaries
- **Auto-rollback** — Deploy failures trigger automatic rollback
- **SARIF** — Security findings uploaded to GitHub Security tab

For detailed documentation, see:
- [CI/CD Pipeline](docs/ci-cd.md)
- [GitHub Actions Design](docs/github-actions.md)
- [Deployment Guide](docs/deployment.md)
- [Rollback Process](docs/rollback.md)

## Monitoring & Observability

### Metrics (Prometheus)

- **Application**: HTTP requests, latency, error rates, Python runtime stats
- **Infrastructure**: CPU, memory, disk, network (via Node Exporter)
- **Database**: Query performance, connections, cache hit ratio (via Postgres Exporter)
- **Gateway**: Request rates, upstream status codes, circuit breaker status

### Logging (Loki + Promtail)

- Structured JSON logging from all services
- Docker container logs collected automatically via Promtail
- Centralized log viewing in Grafana's Explore view

### Dashboards (Grafana)

| Dashboard | Description |
|-----------|-------------|
| **Infrastructure** | CPU, memory, disk, network |
| **Application** | Request rates, latency, error rates |
| **Database** | Query performance, connections, cache hit ratio |
| **Gateway** | Request rates, latency, status codes |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `development` | Application environment |
| `APP_VERSION` | `1.0.0` | Application version |
| `LOG_LEVEL` | `INFO` | Logging level |
| `DB_HOST` | `postgres` | Database host |
| `DB_PORT` | `5432` | Database port |
| `DB_USER` | `employee_user` | Database user |
| `DB_PASSWORD` | `employee_pass` | Database password |
| `DB_NAME` | `employee_db` | Database name |
| `CORS_ORIGINS` | `*` | Allowed CORS origins |
| `GRAFANA_USER` | `admin` | Grafana admin user |
| `GRAFANA_PASSWORD` | `admin` | Grafana admin password |

## Security

- **IMDSv2**: Enforced on EC2 (prevents SSRF-based metadata access)
- **SSH**: Restricted via configurable CIDR variable
- **Grafana/Prometheus**: Access restricted via separate CIDR variables
- **RDS**: Private subnets, EC2-only security group, AES-256 encryption
- **IAM**: EC2 role limited to `AmazonSSMManagedInstanceCore`
- **EBS**: Root volume encrypted (AES-256)
- **Terraform State**: S3 bucket with versioning, encryption, public access blocked
- **State Locking**: DynamoDB prevents concurrent modifications

## Cost Breakdown (AWS Free Tier)

| Service | Configuration | Monthly Cost |
|---------|--------------|-------------|
| EC2 | t3.micro (750 hrs/month) | $0.00 |
| RDS | db.t3.micro (750 hrs/month, 20GB gp3) | $0.00 |
| S3 | 5GB standard storage | $0.00 |
| DynamoDB | PAY_PER_REQUEST (under 25GB) | $0.00 |
| Data Transfer | First 100GB outbound | $0.00 |
| **Total** | | **$0.00** |

## Future Improvements

- [ ] Add authentication (OAuth2 / JWT) via KrakenD
- [ ] Implement automated Grafana dashboard backups
- [ ] Add alerting rules to Prometheus + Alertmanager
- [ ] Set up blue/green deployment with instance swap
- [ ] Implement secrets management (AWS Secrets Manager)
- [ ] Add performance benchmarks and load tests
- [ ] Add end-to-end tests with Playwright
- [ ] Set up pre-commit hooks (pre-commit)
- [ ] Implement database connection pooling (PgBouncer on EC2)

## License

MIT
