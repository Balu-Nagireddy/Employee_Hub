# Employee Hub

A production-ready DevOps showcase project demonstrating **Infrastructure as Code**, **API Gateway Architecture**, **Containerization**, **Monitoring**, **Logging**, and **CI/CD** best practices — all within **AWS Free Tier**.

Built with **FastAPI**, **React**, **KrakenD**, **PostgreSQL**, **Prometheus**, **Grafana**, **Loki**, and **Docker Compose** on a single EC2 instance.

---

## 📊 Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud                                   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                           │   │
│  │                                                                  │   │
│  │  ┌───────────────────────────┐  ┌──────────────────────────┐   │   │
│  │  │    Public Subnets         │  │   Private Subnets        │   │   │
│  │  │    (10.0.0.0/24)          │  │   (10.0.10.0/24)         │   │   │
│  │  │                           │  │                          │   │   │
│  │  │  ┌─────────────────────┐ │  │  ┌────────────────────┐ │   │   │
│  │  │  │  EC2 t3.micro       │ │  │  │  RDS PostgreSQL    │ │   │   │
│  │  │  │                     │ │  │  │  db.t3.micro       │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │                    │ │   │   │
│  │  │  │  │    Nginx      │ │ │  │  │  • Private Subnets │ │   │   │
│  │  │  │  │    :80        │ │ │  │  │  • No Public IP    │ │   │   │
│  │  │  │  └───────────────┘ │ │  │  │  • AES-256 Encrypt │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  • SSL Required    │ │   │   │
│  │  │  │  │   KrakenD     │ │ │  │  └────────────────────┘ │   │   │
│  │  │  │  │   :8080       │ │ │  │                          │   │   │
│  │  │  │  └───────────────┘ │ │  │  ┌────────────────────┐ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  Monitoring Stack  │ │   │   │
│  │  │  │  │   FastAPI     │ │ │  │  │  ┌──────────────┐ │ │   │   │
│  │  │  │  │   :8000       │ │ │  │  │  │  Prometheus │ │ │   │   │
│  │  │  │  └───────────────┘ │ │  │  │  │  :9090      │ │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  └──────────────┘ │ │   │   │
│  │  │  │  │  Prometheus   │ │ │  │  │  ┌──────────────┐ │ │   │   │
│  │  │  │  │  :9090        │ │ │  │  │  │  Grafana     │ │ │   │   │
│  │  │  │  └───────────────┘ │ │  │  │  │  :3001       │ │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  └──────────────┘ │ │   │   │
│  │  │  │  │   Grafana     │ │ │  │  │  ┌──────────────┐ │ │   │   │
│  │  │  │  │   :3001       │ │ │  │  │  │    Loki      │ │ │   │   │
│  │  │  │  └───────────────┘ │ │  │  │  │   :3100      │ │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  └──────────────┘ │ │   │   │
│  │  │  │  │     Loki      │ │ │  │  │  ┌──────────────┐ │ │   │   │
│  │  │  │  │    :3100      │ │ │  │  │  │   Promtail   │ │ │   │   │
│  │  │  │  └───────────────┘ │ │  │  │  │   (Logs)     │ │ │   │   │
│  │  │  │  ┌───────────────┐ │ │  │  │  └──────────────┘ │ │   │   │
│  │  │  │  │   Promtail    │ │ │  │  └────────────────────┘ │   │   │
│  │  │  │  │   (Logs)      │ │ │  │                          │   │   │
│  │  │  │  └───────────────┘ │ │  │                          │   │   │
│  │  │  └─────────────────────┘ │  └──────────────────────────┘   │   │
│  │  │                           │                                  │   │
│  │  └───────────────────────────┘                                  │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │  Internet Gateway (IGW) - Direct Internet Access         │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │  No NAT Gateway - Private subnets are isolated           │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```text
Employee_Hub/
├── .github/                    # GitHub Actions workflows
│   ├── workflows/
│   │   ├── ci.yml              # CI pipeline
│   │   ├── security.yml        # Security scanning
│   │   ├── docker-build.yml    # Docker build and push
│   │   ├── deploy.yml          # Deployment to EC2
│   │   ├── rollback.yml        # Automated rollback
│   │   └── terraform.yml       # Infrastructure management
│   └── actions/                # Reusable actions
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── ec2.tf
│   └── rds.tf
├── services/                   # Application services
│   ├── employee-api/           # FastAPI backend
│   ├── frontend/               # React frontend
│   └── gateway/                # KrakenD API Gateway
├── deployments/                # Deployment configurations
│   └── docker/
│       ├── docker-compose.yml
│       ├── docker-compose.prod.yml
│       ├── prometheus.yml
│       ├── grafana-datasources.yml
│       └── loki-config.yml
└── docs/                       # Documentation
    ├── architecture.md
    ├── ci-cd.md
    ├── deployment.md
    ├── GITHUB_SETUP.md
    └── rollback.md
```

---

## 🛠️ Technology Stack

### Infrastructure
- **Terraform** - Infrastructure as Code
- **AWS** - Cloud Provider
  - VPC with Public/Private Subnets
  - EC2 (t3.micro)
  - RDS PostgreSQL (db.t3.micro)
  - Security Groups, IAM

### Application
- **React + Vite + TypeScript** - Frontend
- **KrakenD** - API Gateway (Self-hosted, replaces ALB)
- **FastAPI + Python** - Backend
- **SQLAlchemy + Alembic** - ORM and Migrations
- **PostgreSQL** - Database

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Container Orchestration (replaces ECS/EKS)
- **GitHub Actions** - CI/CD
- **Trivy** - Security Scanning
- **Amazon ECR** - Container Registry
- **AWS Systems Manager** - Deployment (no SSH)

### Monitoring & Logging
- **Prometheus** - Metrics Collection (replaces CloudWatch)
- **Grafana** - Visualization
- **Loki** - Log Aggregation (replaces CloudWatch Logs)
- **Promtail** - Log Collection
- **Node Exporter** - Host Metrics
- **PostgreSQL Exporter** - Database Metrics

---

## 🚀 How to Set Up and Run the Infrastructure

### Prerequisites
- Docker & Docker Compose
- AWS CLI configured with appropriate permissions
- Terraform >= 1.6
- Python 3.12+ and Node.js 20+ (for local development)

### 1. Local Development
```bash
git clone https://github.com/your-org/Employee_Hub.git
cd Employee_Hub

# Start all services
docker compose up -d
```
Local URLs:
- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080
- **Grafana**: http://localhost:3001 (admin / admin)
- **Prometheus**: http://localhost:9090

### 2. Cloud Infrastructure Provisioning (AWS)
Navigate to the terraform directory:
```bash
cd terraform

# Initialize and format
terraform init
terraform fmt

# Plan the infrastructure
terraform plan -var="db_username=admin_user" -var="db_password=SuperSecretPassword123!"

# Apply the infrastructure
terraform apply -var="db_username=admin_user" -var="db_password=SuperSecretPassword123!"
```

### 3. CI/CD Deployment
Deployment is fully automated using GitHub Actions. Upon merging code to the `main` branch, the pipeline will:
1. Build and push Docker images to GitHub Container Registry (GHCR).
2. Connect to the EC2 instance using AWS Systems Manager (SSM).
3. Pull the latest images and restart the Docker Compose stack.
4. Perform health checks and automatically rollback if services fail to start.

---

## 🔒 Security

### Network Security
- RDS in private subnets (no public access)
- Security Groups with least-privilege rules
- No NAT Gateway (reduced attack surface)
- No SSH exposed - SSM Session Manager only

### Data Security
- EBS root volume encrypted (AES-256)
- RDS encrypted at rest (AES-256)
- SSL required for database connections (`sslmode=require`)

### Access Control
- IAM least-privilege roles
- SSM Session Manager (no SSH keys)
- GitHub Secrets for credentials
- IMDSv2 enforced on EC2

---

## 📊 Monitoring Dashboards

### Infrastructure Dashboard
- CPU, Memory, Disk usage
- Network traffic
- System load
- Running processes

### Application Dashboard
- Request rate by endpoint
- Response time and latency
- HTTP status codes
- Error rate
- Active database connections

### Database Dashboard
- Connections and transactions
- Database size trend
- Cache hit ratio
- Query performance

---

## 💰 Cost Optimization

| Service | Standard Architecture | Free Tier Implementation | Savings |
|---------|----------------------|--------------------------|---------|
| EC2 Instances | $8.47/month | $0 (Free Tier) | $8.47 |
| RDS | $14.40/month | $0 (Free Tier) | $14.40 |
| ALB | $20.00+/month | $0 (KrakenD) | $20.00+ |
| NAT Gateway | $35.00/month | $0 (Not used) | $35.00 |
| ECS Fargate | $30.00+/month | $0 (Docker Compose) | $30.00+ |
| CloudWatch Logs | $15.00+/month | $0 (Loki) | $15.00+ |
| **TOTAL** | **~$200+/month** | **$0** | **~$200+** |

### Key Cost-Saving Decisions

1. **KrakenD instead of ALB**: Self-hosted API Gateway provides superior features at $0
2. **No NAT Gateway**: RDS in private subnets doesn't need outbound internet
3. **Docker Compose instead of ECS/EKS**: Single-node deployment doesn't need orchestration
4. **Self-hosted monitoring**: Prometheus-Grafana-Loki on existing EC2
5. **Single EC2 instance**: Sufficient resources for all 6 containers

---

## 🔑 Secret Management

Secrets and sensitive configurations are managed using secure industry standards:
1. **GitHub Secrets**: Used exclusively in CI/CD pipelines (e.g., AWS credentials, GHCR tokens).
2. **Environment Variables**: Docker Compose utilizes a `.env` file to mount secrets securely into containers at runtime, ensuring they are not hardcoded in the codebase.
3. **Terraform Variables**: Database credentials and AWS keys are passed securely during provisioning via `-var` flags and never committed to state files in plain text.

---

## 💾 Backup Strategy

1. **Database Backups**: Amazon RDS is configured with automated daily snapshots with a 7-day retention period. Point-in-time recovery (PITR) is enabled.
2. **Infrastructure State**: Terraform state is stored securely in a versioned Amazon S3 bucket, preventing accidental deletion and allowing for state rollback if corrupted.
3. **Application Images**: Every successfully built Docker image is versioned and pushed to the container registry, allowing instant rollback in case of deployment failure.

---

## 🔌 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/employees` | List all employees |
| GET | `/api/employees/{id}` | Get employee by ID |
| POST | `/api/employees` | Create new employee |
| PUT | `/api/employees/{id}` | Update employee |
| DELETE | `/api/employees/{id}` | Delete employee |
| GET | `/api/health` | Health check |

---

## 📜 License

MIT
