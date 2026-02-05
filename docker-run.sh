#!/bin/bash

# HotCRP Docker Setup Script
# This script replaces docker-compose with plain docker commands

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we need sudo for docker commands
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "Note: Using sudo for Docker commands"
    else
        echo "Error: Cannot connect to Docker daemon."
        echo "Please ensure Docker is running and you have permission to use it."
        echo "You may need to add your user to the docker group or run with sudo."
        exit 1
    fi
fi

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Network name
NETWORK_NAME="hotcrp-network"

# Container names
SMTP_CONTAINER="hotcrp-smtp"
PHP_CONTAINER="hotcrp-php"
NGINX_CONTAINER="hotcrp-nginx"
MYSQL_CONTAINER="hotcrp-mysql"

# Function to check if container is running
is_container_running() {
    $DOCKER_CMD ps -q -f name=$1 | grep -q .
}

# Function to check if container exists (running or stopped)
container_exists() {
    $DOCKER_CMD ps -aq -f name=$1 | grep -q .
}

# Function to stop and remove container
stop_and_remove_container() {
    if container_exists $1; then
        echo "Stopping and removing existing container: $1"
        $DOCKER_CMD stop $1 2>/dev/null || true
        $DOCKER_CMD rm $1 2>/dev/null || true
    fi
}

# Create network if it doesn't exist
if ! $DOCKER_CMD network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "Creating network: $NETWORK_NAME"
    $DOCKER_CMD network create $NETWORK_NAME
else
    echo "Network $NETWORK_NAME already exists"
fi

# Build PHP image
echo "Building PHP image..."
$DOCKER_CMD build -t hotcrp-php:latest -f docker/php/Dockerfile docker/php

# Stop and remove existing containers
echo "Cleaning up existing containers..."
stop_and_remove_container $NGINX_CONTAINER
stop_and_remove_container $MYSQL_CONTAINER
stop_and_remove_container $PHP_CONTAINER
stop_and_remove_container $SMTP_CONTAINER

# Start SMTP container
echo "Starting SMTP container..."
$DOCKER_CMD run -d \
    --name $SMTP_CONTAINER \
    --network $NETWORK_NAME \
    --network-alias smtp \
    --restart always \
    -p 9002:8025 \
    -e MH_SMTP_BIND_ADDR=0.0.0.0:25 \
    mailhog/mailhog:v1.0.1

# Start PHP container
echo "Starting PHP container..."
$DOCKER_CMD run -d \
    --name $PHP_CONTAINER \
    --network $NETWORK_NAME \
    --network-alias php \
    --restart always \
    -v "$SCRIPT_DIR/app:/srv/www/api" \
    -v "$SCRIPT_DIR/docker/php/www.conf:/usr/local/etc/php-fpm.d/www.conf" \
    -v "$SCRIPT_DIR/docker/php/msmtprc:/etc/msmtprc" \
    -v "$SCRIPT_DIR/docker/php/php.conf:/usr/local/etc/php/conf.d/custom.ini:ro" \
    -v "$SCRIPT_DIR/logs/php:/var/log" \
    -e MYSQL_USER=hotcrp \
    -e MYSQL_PASSWORD=hotcrppwd \
    -e MYSQL_DATABASE=hotcrp \
    -e MYSQL_ROOT_PASSWORD=root \
    -e HOTCRP_PAPER_SITE="${HOTCRP_PAPER_SITE}" \
    -e HOTCRP_CONTACT_NAME="${HOTCRP_CONTACT_NAME}" \
    -e HOTCRP_EMAIL_CONTACT="${HOTCRP_EMAIL_CONTACT}" \
    -e HOTCRP_EMAIL_FROM="${HOTCRP_EMAIL_FROM}" \
    hotcrp-php:latest

# Wait for PHP container to be ready and registered in Docker DNS
echo "Waiting for PHP container to be ready..."
sleep 3

# Start NGINX container
echo "Starting NGINX container..."
$DOCKER_CMD run -d \
    --name $NGINX_CONTAINER \
    --network purdue-monitor \
    --restart always \
    -v "$SCRIPT_DIR/app:/srv/www/api" \
    -v "$SCRIPT_DIR/logs/nginx:/var/log/nginx" \
    -v "$SCRIPT_DIR/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf" \
    -e VIRTUAL_HOST=hotcrp.tsel.purdue.wtf \
    -e LETSENCRYPT_HOST=hotcrp.tsel.purdue.wtf \
    -e LETSENCRYPT_EMAIL=admin@purdue.edu \
    nginx:alpine

# Connect NGINX to internal network for PHP and MySQL access
echo "Connecting NGINX to internal HotCRP network..."
$DOCKER_CMD network connect $NETWORK_NAME $NGINX_CONTAINER

# Start MySQL container
echo "Starting MySQL container..."
$DOCKER_CMD run -d \
    --name $MYSQL_CONTAINER \
    --network $NETWORK_NAME \
    --network-alias mysql \
    --restart always \
    -v "$SCRIPT_DIR/app:/srv/www/api" \
    -v "$SCRIPT_DIR/dbdata:/var/lib/mysql" \
    -e MYSQL_USER=hotcrp \
    -e MYSQL_PASSWORD=hotcrppwd \
    -e MYSQL_DATABASE=hotcrp \
    -e MYSQL_ROOT_PASSWORD=root \
    mysql:8.0.26 \
    --max_allowed_packet=20485760

echo ""
echo "All containers started successfully!"
echo "Note: MySQL may take 30-60 seconds to initialize on first run."
echo ""
echo "Services:"
echo "  - HotCRP Web: http://hotcrp.tsel.purdue.wtf (via nginx-proxy)"
echo "  - HotCRP Web (direct): http://localhost (if nginx-proxy is on port 80)"
echo "  - SMTP (MailHog): http://localhost:9002"
echo ""
echo "Container names:"
echo "  - SMTP: $SMTP_CONTAINER"
echo "  - PHP: $PHP_CONTAINER"
echo "  - NGINX: $NGINX_CONTAINER"
echo "  - MySQL: $MYSQL_CONTAINER"
echo ""
echo "Networks:"
echo "  - External: purdue-monitor (nginx-proxy access)"
echo "  - Internal: $NETWORK_NAME (PHP/MySQL communication)"
echo ""
echo "To view logs, use: docker logs <container-name>"
echo "To stop all containers, run: ./docker-stop.sh"
echo ""
echo "Wait 1-2 minutes for SSL certificate, then test:"
echo "  curl http://hotcrp.tsel.purdue.wtf"
echo ""