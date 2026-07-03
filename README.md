# Employee Hub

A production-ready DevOps showcase project demonstrating **Infrastructure as Code**, **API Gateway Architecture**, **Containerization**, **Monitoring**, **Logging**, and **CI/CD** best practices — all within **AWS Free Tier**.

Built with **FastAPI**, **React**, **KrakenD**, **PostgreSQL**, **Prometheus**, **Grafana**, **Loki**, and **Docker Compose** on a single EC2 instance.

---

## Architecture

```text
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

---

## How to Set Up and Run the Infrastructure

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

## Security Considerations

- **Private Database**: Amazon RDS is deployed in private subnets without public IPs. It is only accessible from the EC2 instance Security Group.
- **IMDSv2**: Enforced on EC2 to prevent SSRF vulnerabilities.
- **Least Privilege IAM**: EC2 instances only have permissions required for AWS Systems Manager (SSM). No SSH keys are provisioned; all access is via SSM Session Manager.
- **Container Isolation**: Docker Compose manages containers in an isolated user-defined bridge network.
- **Encrypted Storage**: EBS root volumes and RDS databases are encrypted using AES-256.
- **Network Filtering**: Security Groups strictly restrict inbound access to ports 80 (Frontend), 3001 (Grafana), and 9090 (Prometheus).
- **SSL Database Connections**: Configured `sslmode=require` in application connection strings.

---

## Cost Optimization Measures

- **Zero Cloud Spend Architecture**: The entire platform runs within the AWS Free Tier limitations.
- **Single EC2 Node**: Utilizing a `t3.micro` instance to run all application and monitoring containers via Docker Compose instead of costly ECS clusters.
- **Self-Hosted API Gateway**: Replacing AWS Application Load Balancer ($20+/month) with a lightweight, containerized KrakenD instance.
- **Self-Hosted Observability**: Using Prometheus, Grafana, and Loki locally instead of paying for CloudWatch Metrics and Logs ($0.50/GB).
- **No NAT Gateway**: Bypassing the need for a NAT Gateway ($35+/month) by structuring the VPC such that the private RDS instance communicates only internally.

---

## Secret Management

Secrets and sensitive configurations are managed using secure industry standards:
1. **GitHub Secrets**: Used exclusively in CI/CD pipelines (e.g., AWS credentials, GHCR tokens).
2. **Environment Variables**: Docker Compose utilizes a `.env` file to mount secrets securely into containers at runtime, ensuring they are not hardcoded in the codebase.
3. **Terraform Variables**: Database credentials and AWS keys are passed securely during provisioning via `-var` flags and never committed to state files in plain text.

---

## Backup Strategy

1. **Database Backups**: Amazon RDS is configured with automated daily snapshots with a 7-day retention period. Point-in-time recovery (PITR) is enabled.
2. **Infrastructure State**: Terraform state is stored securely in a versioned Amazon S3 bucket, preventing accidental deletion and allowing for state rollback if corrupted.
3. **Application Images**: Every successfully built Docker image is versioned and pushed to the container registry, allowing instant rollback in case of deployment failure.

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/employees` | List all employees |
| GET | `/api/employees/{id}` | Get employee by ID |
| POST | `/api/employees` | Create new employee |
| PUT | `/api/employees/{id}` | Update employee |
| DELETE | `/api/employees/{id}` | Delete employee |
| GET | `/api/health` | Health check |

