#!/bin/bash
# -----------------------------------------------------------------------
# EC2 User Data - Employee Hub
#
# Bootstraps the EC2 host only. Terraform provisions infrastructure and
# GitHub Actions deploys the application stack after this script completes.
# -----------------------------------------------------------------------
set -euo pipefail

DEPLOY_LOG="/var/log/employee-hub-deploy.log"
STACK_DIR="/opt/employee-hub"

exec > >(tee -a "$${DEPLOY_LOG}" | logger -t employee-hub-bootstrap)
exec 2>&1

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*"; }
fail()      { log_error "$*"; exit 1; }

log_info "======================================="
log_info "Employee Hub EC2 bootstrap started"
log_info "======================================="

# -----------------------------------------------------------------------
# Phase 1 - System Preparation
# -----------------------------------------------------------------------
log_info "=== Phase 1/4: System Preparation ==="

log_info "Updating system packages..."
dnf upgrade -y

if command -v git >/dev/null 2>&1; then
  log_info "Git already installed"
else
  log_info "Installing Git..."
  dnf install -y git
fi

if command -v jq >/dev/null 2>&1; then
  log_info "jq already installed"
else
  log_info "Installing jq..."
  dnf install -y jq
fi

if command -v wget >/dev/null 2>&1; then
  log_info "wget already installed"
else
  log_info "Installing wget..."
  dnf install -y wget
fi

if command -v unzip >/dev/null 2>&1; then
  log_info "unzip already installed"
else
  log_info "Installing unzip..."
  dnf install -y unzip
fi

if command -v tar >/dev/null 2>&1; then
  log_info "tar already installed"
else
  log_info "Installing tar..."
  dnf install -y tar
fi

log_info "Phase 1/4 complete"

# -----------------------------------------------------------------------
# Phase 2 - Docker, Compose, and Agents
# -----------------------------------------------------------------------
log_info "=== Phase 2/4: Docker, Compose, and Agents ==="

if command -v docker >/dev/null 2>&1; then
  log_info "Docker already installed"
else
  log_info "Installing Docker..."
  dnf install -y docker
fi

log_info "Starting Docker service..."
systemctl enable --now docker
sleep 5
docker info >/dev/null || fail "Docker daemon failed to start"

if groups ec2-user | grep -q docker; then
  log_info "ec2-user already in docker group"
else
  usermod -aG docker ec2-user
  log_info "Added ec2-user to docker group"
fi

if docker compose version >/dev/null 2>&1; then
  log_info "Docker Compose already installed"
else
  log_info "Installing Docker Compose..."
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -SL \
    https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  docker compose version || fail "Docker Compose installation failed"
fi

log_info "Installing and starting SSM Agent..."
if dnf install -y amazon-ssm-agent; then
  log_info "amazon-ssm-agent package installed"
else
  log_warn "amazon-ssm-agent package installation skipped or unavailable"
fi

if systemctl list-unit-files amazon-ssm-agent.service >/dev/null 2>&1; then
  systemctl enable --now amazon-ssm-agent || log_warn "Unable to start amazon-ssm-agent"
else
  log_warn "amazon-ssm-agent service not found"
fi

log_info "Installing CloudWatch Agent if available..."
dnf install -y amazon-cloudwatch-agent || log_warn "amazon-cloudwatch-agent package unavailable"

log_info "Docker Version"
docker --version

log_info "Docker Compose Version"
docker compose version

log_info "Git Version"
git --version

log_info "Phase 2/4 complete"

# -----------------------------------------------------------------------
# Phase 3 - Application Directory and Environment
# -----------------------------------------------------------------------
log_info "=== Phase 3/4: Application Directory and Environment ==="

install -d \
  -o ec2-user \
  -g ec2-user \
  -m 755 \
  "$${STACK_DIR}"

log_info "Creating application environment file..."
cat > "$${STACK_DIR}/.env" << 'ENVEOF'
# Database - substituted by Terraform templatefile()
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}

# Environment
APP_ENV=${environment}

# Service URLs (Docker networking)
GATEWAY_URL=http://gateway:8080
API_URL=http://employee-api:8000
FRONTEND_URL=http://frontend:80

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_URL=http://grafana:3001
LOKI_URL=http://loki:3100

# PostgreSQL Exporter
DATA_SOURCE_NAME=postgresql://${db_username}:${db_password}@${db_host}:${db_port}/${db_name}?sslmode=require
ENVEOF

chown ec2-user:ec2-user "$${STACK_DIR}/.env"
chmod 600 "$${STACK_DIR}/.env"
log_info ".env file created at $${STACK_DIR}/.env"

log_info "Checking RDS connectivity..."
if timeout 10 bash -c "</dev/tcp/${db_host}/${db_port}"; then
  log_info "RDS reachable at ${db_host}:${db_port}"
else
  log_warn "RDS not reachable yet at ${db_host}:${db_port}"
fi

log_info "Phase 3/4 complete"

# -----------------------------------------------------------------------
# Phase 4 - Bootstrap Summary
# -----------------------------------------------------------------------
log_info "=== Phase 4/4: Bootstrap Summary ==="

TOKEN=$(curl -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds:21600" \
  -s || true)

if [ -n "$${TOKEN}" ]; then
  PUBLIC_IP=$(curl \
    -H "X-aws-ec2-metadata-token:$${TOKEN}" \
    -s \
    http://169.254.169.254/latest/meta-data/public-ipv4 || true)
else
  PUBLIC_IP=""
fi

log_info "Public IP: $${PUBLIC_IP:-unknown}"

log_info "Disk Usage"
df -h

log_info "Memory"
free -m

log_info "Docker containers"
docker ps -a || true

if [ ! -f "$${STACK_DIR}/deployments/docker/docker-compose.prod.yml" ]; then
  log_warn "Production compose file not found yet."
  log_warn "This is expected before GitHub Actions deployment."
else
  log_info "Production compose file detected."
fi

log_info "======================================="
log_info "Employee Hub EC2 bootstrap completed."
log_info "Infrastructure ready."
log_info "Waiting for GitHub Actions deployment."
log_info "======================================="
