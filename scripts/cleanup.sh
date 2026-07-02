#!/bin/bash
set -euo pipefail

# Employee Hub Cleanup Script
# Usage: ./cleanup.sh [all]

echo "🧹 Employee Hub Cleanup"
echo "======================"

if [ "${1:-}" = "all" ]; then
    echo "⚠️  Full cleanup mode - removing everything..."
    echo ""

    echo "📦 Stopping and removing containers..."
    docker compose down -v 2>/dev/null || true

    echo "🗑️  Removing images..."
    docker rmi employee-hub-frontend:latest 2>/dev/null || true
    docker rmi employee-hub-employee-api:latest 2>/dev/null || true

    echo "🧹 Pruning system..."
    docker system prune -f 2>/dev/null || true

    echo ""
    echo "✅ Full cleanup complete!"
else
    echo "📦 Stopping containers (keeping volumes)..."
    docker compose down 2>/dev/null || true
    echo ""
    echo "✅ Containers stopped. Volumes preserved."
    echo "   To fully clean up, run: ./cleanup.sh all"
fi
