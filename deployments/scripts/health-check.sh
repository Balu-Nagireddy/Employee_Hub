#!/bin/bash
set -euo pipefail

# Health Check Script
# Checks all services health endpoints

echo "🔍 Employee Hub Health Check"
echo "=========================="
echo ""

check_endpoint() {
    local name=$1
    local url=$2
    local expected=$3

    if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null); then
        if [ "$response" = "$expected" ]; then
            echo "✅ $name: Healthy (HTTP $response)"
        else
            echo "⚠️  $name: Degraded (HTTP $response, expected $expected)"
        fi
    else
        echo "❌ $name: Unreachable"
    fi
}

echo "Services:"
echo "--------"
check_endpoint "Frontend"       "http://localhost:3000" "200"
check_endpoint "Gateway"        "http://localhost:8080/health" "200"
check_endpoint "Employee API"   "http://localhost:8000/health" "200"
check_endpoint "Prometheus"     "http://localhost:9090/-/healthy" "200"
check_endpoint "Grafana"        "http://localhost:3001/api/health" "200"
check_endpoint "Loki"           "http://localhost:3100/ready" "200"
check_endpoint "Node Exporter"  "http://localhost:9100/metrics" "200"
echo ""

echo "Database:"
echo "--------"
check_endpoint "PostgreSQL"     "http://localhost:8000/ready" "200"
echo ""

echo "Metrics:"
echo "-------"
check_endpoint "Employee API Metrics" "http://localhost:8000/metrics" "200"
echo ""

echo "=========================="
echo "✅ Health check complete"
