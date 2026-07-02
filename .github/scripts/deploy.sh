#!/bin/bash
# =============================================================================
# Employee Hub — Remote Deploy Script
#
# Runs on the EC2 instance via AWS SSM Run Command.
# Pulls the latest Docker images and restarts the application stack.
#
# Environment variables (set by the calling workflow):
#   STACK_DIR        — Base directory on EC2 (/opt/employee-hub)
#   COMPOSE_FILE     — Path to docker-compose.prod.yml (relative to STACK_DIR)
#   IMAGE_TAG        — Docker image tag to deploy (git SHA)
#   REGISTRY         — Container registry URL (ECR repository URI)
#   AWS_DEFAULT_REGION — AWS region
#   DB_HOST          — RDS endpoint
#   DB_PORT          — RDS port
#   DB_USER          — RDS username
#   DB_PASSWORD      — RDS password
#   DB_NAME          — RDS database name
#   PREVIOUS_TAG     — Previous image tag (for rollback)
# =============================================================================

set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/employee-hub}"
COMPOSE_FILE="${COMPOSE_FILE:-deployments/docker/docker-compose.prod.yml}"
DEPLOY_LOG="/var/log/employee-hub-deploy.log"
ROLLBACK_TRIGGERED=false

exec > >(tee -a "${DEPLOY_LOG}") 2>&1

log_info()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
log_warn()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*"; }
log_error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"; }
log_sec()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SEC]   $*"; }

cleanup() {
    local exit_code=$?
    log_info "Deploy script finished with exit code ${exit_code}"
    echo "DEPLOY_STATUS=${exit_code}" >> "${STACK_DIR}/.deploy-status"
    exit "${exit_code}"
}
trap cleanup EXIT

# -------------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------------
validate_env() {
    local missing=0
    for var in STACK_DIR COMPOSE_FILE IMAGE_TAG REGISTRY; do
        if [ -z "${!var:-}" ]; then
            log_error "Required variable ${var} is not set"
            missing=1
        fi
    done

    if [ ! -f "${STACK_DIR}/${COMPOSE_FILE}" ]; then
        log_error "Compose file not found: ${STACK_DIR}/${COMPOSE_FILE}"
        missing=1
    fi

    if [ "${missing}" -ne 0 ]; then
        log_error "Environment validation failed — aborting deployment"
        exit 1
    fi
}

# -------------------------------------------------------------------------
# Health check
# -------------------------------------------------------------------------
check_service() {
    local name=$1
    local url=$2
    local expected=$3
    local retries=${4:-6}
    local delay=${5:-10}

    log_info "Checking ${name} at ${url}..."

    for i in $(seq 1 "${retries}"); do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}" 2>/dev/null || echo "000")
        if [ "${http_code}" = "${expected}" ]; then
            log_info "  ✅ ${name} is healthy (HTTP ${http_code})"
            return 0
        fi
        log_info "  Attempt ${i}/${retries} — ${name} returned HTTP ${http_code}, retrying in ${delay}s..."
        sleep "${delay}"
    done

    log_error "  ❌ ${name} did not become healthy after ${retries} attempts"
    return 1
}

# -------------------------------------------------------------------------
# Main deployment
# -------------------------------------------------------------------------
deploy_stack() {
    local tag="${1:-${IMAGE_TAG}}"
    local deployment_start
    deployment_start=$(date +%s)

    log_info "============================================================"
    log_info "Deploying Employee Hub"
    log_info "  Timestamp:     $(date)"
    log_info "  Image Tag:     ${tag}"
    log_info "  Registry:      ${REGISTRY}"
    log_info "  Stack Dir:     ${STACK_DIR}"
    log_info "  Compose File:  ${COMPOSE_FILE}"
    log_info "============================================================"

    validate_env

    cd "${STACK_DIR}"

    # Export variables for docker-compose.prod.yml
    export IMAGE_TAG="${tag}"
    export REGISTRY
    export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME
    export APP_ENV="${APP_ENV:-production}"
    export APP_VERSION="${APP_VERSION:-1.0.0}"
    export LOG_LEVEL="${LOG_LEVEL:-INFO}"
    export CORS_ORIGINS="${CORS_ORIGINS:-*}"

    # Log in to ECR
    log_info "Authenticating to Amazon ECR..."
    aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | \
        docker login --username AWS --password-stdin "${REGISTRY%/*}" || {
        log_error "ECR authentication failed"
        return 1
    }

    # Pull latest images
    log_info "Pulling Docker images (tag: ${tag})..."
    docker compose -f "${COMPOSE_FILE}" pull 2>&1 || {
        log_error "Failed to pull Docker images"
        return 1
    }

    # Restart the stack
    log_info "Restarting application stack..."
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans 2>&1 || {
        log_error "Failed to start Docker Compose stack"
        return 1
    }

    # Wait for containers to initialize
    log_info "Waiting for containers to initialize..."
    sleep 15

    # Verify running containers
    log_info "Running containers:"
    docker compose -f "${COMPOSE_FILE}" ps 2>&1

    # Health checks
    log_info "Performing health checks..."
    local all_healthy=true

    check_service "Employee API (via KrakenD)"    "http://localhost:8080/health"  "200" 12 10 || all_healthy=false
    check_service "KrakenD Gateway" "http://localhost:8080/health"  "200" 12 10 || all_healthy=false
    check_service "Frontend"        "http://localhost:80/"          "200" 6  10 || all_healthy=false
    check_service "Prometheus"      "http://localhost:9090/-/healthy" "200" 6 10 || all_healthy=false
    check_service "Grafana"         "http://localhost:3001/api/health" "200" 6 10 || all_healthy=false
    check_service "Loki"           "http://localhost:3100/ready"    "200" 6  10 || all_healthy=false

    local deployment_end
    deployment_end=$(date +%s)
    local duration=$((deployment_end - deployment_start))

    if [ "${all_healthy}" = true ]; then
        log_info "============================================================"
        log_info "✅ Deployment completed successfully"
        log_info "   Duration: ${duration}s"
        log_info "   Image Tag: ${tag}"
        log_info "============================================================"
        return 0
    else
        log_error "============================================================"
        log_error "❌ Deployment completed with health check failures"
        log_error "   Duration: ${duration}s"
        log_error "============================================================"
        return 1
    fi
}

# -------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------
deploy_stack "$@"
