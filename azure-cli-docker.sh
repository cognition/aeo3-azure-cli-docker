#!/usr/bin/env bash
# Azure CLI Docker Container Connection Script
# Usage: azure-cli-docker.sh [container-name-or-id]

set -euo pipefail

CONTAINER_NAME="${1:-azure-cli}"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '${CONTAINER_NAME}' not found." >&2
    echo "Available containers:" >&2
    docker ps -a --format '  {{.Names}} ({{.Status}})' >&2
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is not running. Starting it..." >&2
    docker start "${CONTAINER_NAME}" >/dev/null
    sleep 1
fi

# Execute bash in the container
exec docker exec -it "${CONTAINER_NAME}" /bin/bash
