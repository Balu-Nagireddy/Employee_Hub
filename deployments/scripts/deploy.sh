#!/bin/bash
set -euo pipefail

# Employee Hub Deployment Script
# Usage: ./deploy.sh [environment]

ENV=${1:-development}
COMPOSE_FILE="../docker/docker-compose.prod.yml"

echo "🚀 Deploying Employee Hub - ${ENV}"

if [ "$ENV" = "production" ]; then
    echo "📦 Using production compose file: ${COMPOSE_FILE}"
    if [ ! -f ".env" ]; then
        echo "❌ .env file not found. Please create one from .env.example"
        exit 1
    fi
    docker compose -f docker-compose.yml -f "${COMPOSE_FILE}" --env-file .env up -d
else
    echo "🔧 Starting development environment..."
    docker compose up -d
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Services:"
echo "   Frontend:     http://localhost:3000"
echo "   Gateway:      http://localhost:8080"
echo "   API (direct): http://localhost:8000"
echo "   Prometheus:   http://localhost:9090"
echo "   Grafana:      http://localhost:3001"
echo "   Loki:         http://localhost:3100"
echo ""
echo "📋 To check status: docker compose ps"
echo "📋 To view logs:    docker compose logs -f"
