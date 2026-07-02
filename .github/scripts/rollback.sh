#!/bin/bash
# =============================================================================
# Employee Hub — Remote Rollback Script
#
# Runs on the EC2 instance via AWS SSM Run Command.
# Redeploys the last known good image version and restarts the stack.
#
# Environment variables (set by the calling workflow):
#   STACK_DIR        — Base directory on EC2 (/opt/employee-hub)
#   COMPOSE_FILE     — Path to docker-compose.prod.yml
#   IMAGE_TAG        — Current (failed) image tag
#   PREVIOUS_TAG     — Last known good image tag to roll back to
#   REGISTRY         — Container registry URL
#   AWS_DEFAULT_REGION — AWS region
#   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
# =============================================================================

set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/employee-hub}"
COMPOSE_FILE="${COMPOSE_FILE:-deployments/docker/docker-compose.prod.yml}"
ROLLBACK_LOG="/var/log/employee-hub-rollback.log"

exec > >(tee -a "${ROLLBACK_LOG}") 2>&1

log_info()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
log_error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"; }

cleanup() {
    local exit_code=$?
    log_info "Rollback script finished with exit code ${exit_code}"
    echo "ROLLBACK_STATUS=${exit_code}" >> "${STACK_DIR}/.rollback-status"
    exit "${exit_code}"
}
trap cleanup EXIT

# -------------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------------
validate_env() {
    local missing=0
    for var in STACK_DIR COMPOSE_FILE PREVIOUS_TAG REGISTRY; do
        if [ -z "${!var:-}" ]; then
            log_error "Required variable ${var} is not set"
            missing=1
        fi
    done

    if [ "${missing}" -ne 0 ]; then
        log_error "Environment validation failed — aborting rollback"
        exit 1
    fi
}

# -------------------------------------------------------------------------
# Main rollback
# -------------------------------------------------------------------------
rollback_stack() {
    local rollback_start
    rollback_start=$(date +%s)

    log_info "============================================================"
    log_info "🔄 ROLLBACK — Reverting to previous deployment"
    log_info "  Timestamp:      $(date)"
    log_info "  Current Tag:    ${IMAGE_TAG:-unknown}"
    log_info "  Previous Tag:   ${PREVIOUS_TAG}"
    log_info "  Registry:       ${REGISTRY}"
    log_info "  Stack Dir:      ${STACK_DIR}"
    log_info "============================================================"

    validate_env

    cd "${STACK_DIR}"

    # Export variables
    export IMAGE_TAG="${PREVIOUS_TAG}"
    export REGISTRY
    export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME
    export APP_ENV="${APP_ENV:-production}"
    export APP_VERSION="${APP_VERSION:-1.0.0}"
    export LOG_LEVEL="${LOG_LEVEL:-INFO}"
    export CORS_ORIGINS="${CORS_ORIGINS:--*}"

    # Log in to ECR
    log_info "Authenticating to Amazon ECR..."
    aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" | \
        docker login --username AWS --password-stdin "${REGISTRY%/*}" || {
        log_error "ECR authentication failed"
        return 1
    }

    # Pull the previous image
    log_info "Pulling previous images (tag: ${PREVIOUS_TAG})..."
    docker compose -f "${COMPOSE_FILE}" pull 2>&1 || {
        log_error "Failed to pull previous Docker images"
        return 1
    }

    # Restart the stack with the previous tag
    log_info "Restarting stack with previous images..."
    docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans 2>&1 || {
        log_error "Failed to restart Docker Compose stack"
        return 1
    }

    # Verify
    log_info "Running containers after rollback:"
    docker compose -f "${COMPOSE_FILE}" ps 2>&1

    local rollback_end
    rollback_end=$(date +%s)
    local duration=$((rollback_end - rollback_start))

    log_info "============================================================"
    log_info "Rollback complete (duration: ${duration}s)"
    log_info "Deployed tag: ${PREVIOUS_TAG}"
    log_info "============================================================"

    return 0
}

# -------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------
rollback_stack "$@"
