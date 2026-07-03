# Employee Hub Architecture

## System Architecture

```
                         ┌──────────────────┐
                         │   AWS Cloud       │
                         │                   │
┌──────────┐             │  ┌────────────┐   │
│ Browser  │─────────────┼──▶   EC2       │   │
│ (React)  │ HTTP/HTTPS  │  │  Instance   │   │
└──────────┘             │  │  (t3.micro) │   │
                         │  │             │   │
                         │  │  ┌───────┐  │   │
                         │  │  │ Nginx │  │   │
                         │  │  │(React)│  │   │
                         │  │  └───┬───┘  │   │
                         │  │      │      │   │
                         │  │  ┌───▼───┐  │   │
                         │  │  │KrakenD│  │   │
                         │  │  │Gateway│  │   │
                         │  │  └───┬───┘  │   │
                         │  │      │      │   │
                         │  │  ┌───▼───┐  │   │
                         │  │  │FastAPI│  │   │
                         │  │  │Backend│  │   │
                         │  │  └───┬───┘  │   │
                         │  │      │      │   │
                         │  └──────┼──────┘   │
                         │         │          │
                         │  ┌──────▼──────┐   │
                         │  │    RDS       │   │
                         │  │  PostgreSQL  │   │
                         │  │ (db.t3.micro)│   │
                         │  │ [Private]    │   │
                         │  └─────────────┘   │
                         │                    │
                         │  Monitoring Stack  │
                         │  ┌───┐ ┌────┐      │
                         │  │Prm│ │Grf │      │
                         │  │ths│ │ana │      │
                         │  └───┘ └────┘      │
                         │  ┌──┐ ┌───────┐   │
                         │  │Lk│ │Pr mtl│   │
                         │  │i │ │      │   │
                         │  └──┘ └───────┘   │
                         └──────────────────┘
```

## Network Topology

```
┌──────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                  │
│                                                       │
│  ┌─────────────────────┐  ┌──────────────────────┐   │
│  │   Public Subnets    │  │   Private Subnets     │   │
│  │   10.0.0.0/24       │  │   10.0.10.0/24        │   │
│  │   10.0.1.0/24       │  │   10.0.11.0/24        │   │
│  │                     │  │                        │   │
│  │  ┌───────────────┐  │  │  ┌────────────────┐    │   │
│  │  │ EC2 Instance  │  │  │  │  RDS PostgreSQL │    │   │
│  │  │ (t3.micro)    │◀─┼──┼──▶│ (db.t3.micro)  │    │   │
│  │  └───────────────┘  │  │  └────────────────┘    │   │
│  │         │           │  │                        │   │
│  │  ┌──────▼──────┐    │  │  No NAT Gateway —      │   │
│  │  │  Internet   │    │  │  private subnets used   │   │
│  │  │  Gateway    │    │  │  only for RDS isolation │   │
│  │  └─────────────┘    │  │                        │   │
│  └─────────────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

## Component Details

### Frontend (React + Vite + TypeScript)
- Single-page application served via Nginx on port 80
- Static assets with long-term caching headers
- API calls proxied through Nginx to KrakenD Gateway at `/api/*`
- All client-side routing handled by React Router

### API Gateway (KrakenD)
- Single entry point for all client → backend communication
- Route mapping, CORS handling, rate limiting, circuit breaker
- Health check endpoint at `/health`
- Metrics exposed on port 8090
- Backend services are never exposed directly to clients

### Backend (FastAPI + Python)
- RESTful Employee CRUD API
- SQLAlchemy ORM with PostgreSQL connection pooling
- Structured JSON logging via structlog
- Prometheus metrics on `/metrics` endpoint
- OpenAPI/Swagger documentation at `/docs`

### Database (PostgreSQL on RDS)
- Managed PostgreSQL 16 on `db.t3.micro` (Free Tier)
- Deployed in private subnets — no public access
- Encrypted at rest (AES-256)
- Automated daily backups (7-day retention)
- Only accessible from the EC2 security group

### Monitoring Stack
| Service     | Port  | Purpose                          |
|-------------|-------|----------------------------------|
| Prometheus  | 9090  | Metrics collection & storage     |
| Grafana     | 3001  | Dashboard visualization          |
| Loki        | 3100  | Log aggregation                  |
| Promtail    | —     | Docker container log collection  |
| Node Exp.   | 9100  | Host-level metrics               |
| PG Exp.     | 9187  | Database metrics                 |

## Communication Flow

1. **Browser** → **Nginx (port 80)**: React SPA loads, assets served with cache headers
2. **Nginx** → **KrakenD (port 8080)**: `/api/*` requests proxied to gateway
3. **KrakenD** → **FastAPI (port 8000)**: Business logic executed, data fetched
4. **FastAPI** → **RDS (port 5432)**: Database queries via SQLAlchemy
5. **All external API consumers** (Postman, scripts) → **KrakenD only**
6. FastAPI is never exposed directly to external clients

## Architecture Decision Records (ADRs)

### ADR-001: KrakenD Instead of ALB

**Context:** The assignment required an API Gateway / Load Balancer. AWS ALB is a common choice.

**Decision:** Use KrakenD (self-hosted API Gateway) instead of ALB.

**Rationale:**
- AWS ALB adds ~$20/month cost, exceeding Free Tier budget
- KrakenD provides API gateway features (routing, rate limiting, circuit breaker, metrics) that ALB does not
- KrakenD runs on the same EC2 instance — no additional infrastructure
- KrakenD allows fine-grained control over API policies
- Maintains separation of concerns: KrakenD handles gateway logic, Nginx handles static serving

**Trade-offs:**
- Single point of failure (one EC2 instance) — acceptable for demo/assignment scope
- Less弹性 than managed ALB — but sufficient for the load levels in this project

### ADR-002: Docker Compose Instead of ECS

**Context:** Container orchestration was required. AWS ECS Fargate is the managed alternative.

**Decision:** Use Docker Compose for container orchestration on a single EC2 instance.

**Rationale:**
- ECS Fargate would incur ~$30+/month for the services in this stack
- Docker Compose is zero-cost beyond the EC2 instance itself
- Simplified deployment: `docker compose up -d` vs. ECS task definitions + service updates
- All containers run on one host, so the orchestration complexity of ECS/Kubernetes is unnecessary
- Docker Compose profiles allow running the database on RDS vs. locally as needed

**Trade-offs:**
- No built-in auto-scaling — acceptable for demo/assignment scope
- Manual container placement — fine for a single-node deployment
- No orchestration-native rolling updates — handled via CI/CD SSH deploy script

### ADR-003: Single EC2 Instance Instead of Kubernetes

**Context:** The assignment required containerized deployment. Kubernetes (EKS) is a common production choice.

**Decision:** Use a single EC2 instance running Docker Compose instead of a Kubernetes cluster.

**Rationale:**
- EKS cluster costs ~$73/month (control plane) before any worker nodes
- A single `t3.micro` EC2 instance ($8.47/month) is Free Tier eligible
- The application stack (6 containers) fits comfortably on a single instance
- Kubernetes operational overhead is unjustified for a 6-container demo application
- Docker Compose provides adequate orchestration for single-host deployments

**Trade-offs:**
- No multi-host orchestration — not needed for this scope
- No built-in pod auto-healing — Docker Compose restart policies cover most cases
- Upgrade path to Kubernetes exists if the application grows

### ADR-004: No NAT Gateway

**Context:** Private subnets typically require a NAT Gateway for outbound internet access.

**Decision:** Omit NAT Gateway entirely.

**Rationale:**
- NAT Gateway costs ~$35/month — significant relative to project budget
- RDS in private subnets does not need outbound internet access
- Private subnets exist solely for RDS isolation, not for compute workloads
- EC2 runs in public subnets and accesses the internet via Internet Gateway

**Impact:**
- RDS cannot initiate outbound connections — it doesn't need to
- Security: RDS is fully isolated from the internet by being in private subnets
- Cost savings: ~$35/month

### ADR-005: RDS in Private Subnets

**Context:** Database placement decision for security and architecture.

**Decision:** Deploy RDS PostgreSQL in private subnets with no public access.

**Rationale:**
- Industry best practice for database security
- RDS is only accessible from the EC2 security group on port 5432
- No public endpoint reduces attack surface
- Meets compliance requirements for data isolation

**Implementation:**
- RDS subnet group spans both private subnets
- Security group allows ingress only from the EC2 security group
- `publicly_accessible = false`
- Storage encryption enabled (AES-256)

### ADR-006: AWS Free Tier Design Decisions

**Context:** The project must operate within AWS Free Tier constraints.

**Decisions:**
| Resource | Choice | Free Tier Limit | Monthly Cost |
|---|---|---|---|
| EC2 | t3.micro (2 vCPU, 1GB RAM) | 750 hours/month | $0 (Free Tier) |
| RDS | db.t3.micro (1 vCPU, 1GB RAM, 20GB gp3) | 750 hours/month | $0 (Free Tier) |
| S3 | Standard (for Terraform state) | 5GB | $0 (Free Tier) |
| DynamoDB | PAY_PER_REQUEST (Terraform lock) | 25GB | $0 (Free Tier) |
| Data Transfer | Internet Gateway | 100GB outbound | $0 (Free Tier) |

**Avoided Paid Services:**
| Service | Reason |
|---|---|
| ALB | $20+/month — KrakenD provides equivalent functionality |
| ECS Fargate | $30+/month — Docker Compose on single EC2 |
| NAT Gateway | $35+/month — not needed (RDS in private subnets, EC2 in public) |
| EKS | $73+/month — single EC2 sufficient |
| CloudWatch Logs | $0.50/GB ingested — Loki + Promtail on EC2 is free |

## Security Architecture

- **IMDSv2**: Enforced on EC2 (requires session tokens for metadata access)
- **SSH**: Restricted via `allowed_ssh_cidr` variable (default: 0.0.0.0/0 for setup, restrict in prod)
- **Grafana/Prometheus**: Access restricted via separate CIDR variables
- **RDS**: Private subnets, EC2 security group only, encryption at rest
- **IAM**: EC2 role limited to `AmazonSSMManagedInstanceCore` (SSM Session Manager only)
- **EBS**: Root volume encrypted (AES-256)
- **Terraform State**: S3 bucket with versioning + encryption, DynamoDB locking

## Deployment Pipeline

```
Git Push → GitHub Actions → Build Images → Push to GHCR → SSH via SSM → Docker Compose Up
```

1. Developer pushes to `main` branch
2. GitHub Actions runs tests, linting, security scan
3. Docker images built and pushed to GitHub Container Registry
4. SSM Send-Command executes remote deploy script on EC2
5. EC2 pulls latest images and runs `docker compose up -d`
6. Health check verifies KrakenD `/health` endpoint

## Identity and Access Management

- **CI/CD**: GitHub Actions uses AWS credentials (configured via secrets) for SSM commands
- **EC2**: Instance profile with `AmazonSSMManagedInstanceCore` for Session Manager access
- **SSH**: Optional key pair for emergency access; SSM preferred
- **Secrets**: Database credentials passed via Terraform variables, stored in `.env` on EC2
