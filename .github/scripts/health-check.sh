#!/bin/bash
# =============================================================================
# Employee Hub — Remote Health Check Script
#
# Runs on the EC2 instance via AWS SSM Run Command.
# Verifies that all application services are healthy.
# =============================================================================

set -euo pipefail

HEALTH_LOG="/var/log/employee-hub-health.log"

exec > >(tee -a "${HEALTH_LOG}") 2>&1

log_info()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PASS]  $*"; }
log_error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FAIL]  $*"; }

check_service() {
    local name=$1
    local url=$2
    local expected=$3
    local retries=${4:-3}
    local delay=${5:-5}

    for i in $(seq 1 "${retries}"); do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}" 2>/dev/null || echo "000")
        if [ "${http_code}" = "${expected}" ]; then
            log_success "${name}: HTTP ${http_code}"
            return 0
        fi
        if [ "${i}" -lt "${retries}" ]; then
            sleep "${delay}"
        fi
    done

    log_error "${name}: Expected HTTP ${expected}, got HTTP ${http_code:-unreachable}"
    return 1
}

log_info "============================================================"
log_info "Employee Hub Health Check"
log_info "Timestamp: $(date)"
log_info "============================================================"

failed=0

echo ""
echo "--- Application Services ---"
check_service "Employee API"    "http://localhost:8000/health"  "200" || ((failed++))
check_service "KrakenD Gateway" "http://localhost:8080/health"  "200" || ((failed++))
check_service "Frontend"        "http://localhost:80/"          "200" || ((failed++))

echo ""
echo "--- Monitoring Stack ---"
check_service "Prometheus"  "http://localhost:9090/-/healthy" "200" || ((failed++))
check_service "Grafana"     "http://localhost:3001/api/health" "200" || ((failed++))
check_service "Loki"       "http://localhost:3100/ready"    "200" || ((failed++))

echo ""
echo "--- Docker Status ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1 || true

echo ""
echo "============================================================"
if [ "${failed}" -eq 0 ]; then
    log_success "All services healthy"
    exit 0
else
    log_error "${failed} service(s) failed health check"
    exit 1
fi
