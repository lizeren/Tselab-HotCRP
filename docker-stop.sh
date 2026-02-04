#!/bin/bash

# HotCRP Docker Stop Script
# This script stops and removes all HotCRP containers

set -e

# Check if we need sudo for docker commands
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "Note: Using sudo for Docker commands"
    else
        echo "Error: Cannot connect to Docker daemon."
        exit 1
    fi
fi

# Container names
SMTP_CONTAINER="hotcrp-smtp"
PHP_CONTAINER="hotcrp-php"
NGINX_CONTAINER="hotcrp-nginx"
MYSQL_CONTAINER="hotcrp-mysql"
NETWORK_NAME="hotcrp-network"

echo "Stopping HotCRP containers..."

# Stop and remove containers
$DOCKER_CMD stop $NGINX_CONTAINER 2>/dev/null || true
$DOCKER_CMD rm $NGINX_CONTAINER 2>/dev/null || true

$DOCKER_CMD stop $MYSQL_CONTAINER 2>/dev/null || true
$DOCKER_CMD rm $MYSQL_CONTAINER 2>/dev/null || true

$DOCKER_CMD stop $PHP_CONTAINER 2>/dev/null || true
$DOCKER_CMD rm $PHP_CONTAINER 2>/dev/null || true

$DOCKER_CMD stop $SMTP_CONTAINER 2>/dev/null || true
$DOCKER_CMD rm $SMTP_CONTAINER 2>/dev/null || true

echo "All containers stopped and removed."
echo ""
echo "Note: Network '$NETWORK_NAME' and data volumes are preserved."
echo "To remove the network, run: docker network rm $NETWORK_NAME"
echo "To remove data volumes, delete the ./dbdata directory"
echo ""
