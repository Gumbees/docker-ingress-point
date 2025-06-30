#!/bin/bash

# ==============================================================================
# Connect Traefik to Multiple App Networks
# ==============================================================================
# This script helps you connect the Traefik container to multiple app networks
# Usage: ./connect-networks.sh [network1] [network2] [network3] ...
# Or edit the APP_NETWORKS array below and run without arguments

set -e

# Load environment variables if .env exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default container name prefix
CONTAINER_NAME_PREFIX=${CONTAINER_NAME_PREFIX:-ingress}
TRAEFIK_CONTAINER="${CONTAINER_NAME_PREFIX}-traefik"

# Default networks to connect to (edit as needed)
DEFAULT_NETWORKS=(
    "media_center_apps"
    # Add your app networks here
    # "app1_network"
    # "app2_network"
)

# Use command line arguments if provided, otherwise use defaults
if [ $# -gt 0 ]; then
    APP_NETWORKS=("$@")
else
    APP_NETWORKS=("${DEFAULT_NETWORKS[@]}")
fi

echo "🔌 Connecting Traefik to app networks..."
echo "Container: $TRAEFIK_CONTAINER"
echo ""

# Check if Traefik container exists and is running
if ! docker ps --format '{{.Names}}' | grep -q "^${TRAEFIK_CONTAINER}$"; then
    echo "❌ Error: Traefik container '$TRAEFIK_CONTAINER' is not running."
    echo "Please start the docker-compose stack first:"
    echo "   docker-compose up -d"
    exit 1
fi

# Connect to each network
for network in "${APP_NETWORKS[@]}"; do
    echo "🔌 Connecting to $network..."
    
    # Check if network exists
    if ! docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
        echo "⚠️  Warning: Network '$network' does not exist. Skipping..."
        continue
    fi
    
    # Connect to network (suppress error if already connected)
    if docker network connect "$network" "$TRAEFIK_CONTAINER" 2>/dev/null; then
        echo "✅ Connected to $network"
    else
        echo "ℹ️  Already connected to $network"
    fi
done

echo ""
echo "🌐 Traefik is now connected to these networks:"

# List all connected networks
if command -v jq >/dev/null 2>&1; then
    docker inspect "$TRAEFIK_CONTAINER" | jq -r '.[0].NetworkSettings.Networks | keys[]' | sed 's/^/   /'
else
    # Fallback if jq is not available
    docker inspect "$TRAEFIK_CONTAINER" --format '{{range $net, $v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' | sed 's/^/   /'
fi

echo ""
echo "🎉 Done! Traefik can now discover services on all connected networks."
echo ""
echo "💡 Tip: Services on these networks can now be exposed by adding Traefik labels"
echo "   to their docker-compose configurations." 