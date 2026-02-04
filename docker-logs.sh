#!/bin/bash

# HotCRP Docker Logs Script
# This script helps you view logs from HotCRP containers

# Check if we need sudo for docker commands
DOCKER_CMD="docker"
if ! docker ps >/dev/null 2>&1; then
    if sudo docker ps >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
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

if [ -z "$1" ]; then
    echo "Usage: ./docker-logs.sh [service] [options]"
    echo ""
    echo "Services:"
    echo "  smtp    - View SMTP (MailHog) logs"
    echo "  php     - View PHP-FPM logs"
    echo "  nginx   - View NGINX logs"
    echo "  mysql   - View MySQL logs"
    echo "  all     - View all logs together"
    echo ""
    echo "Options (passed to docker logs):"
    echo "  -f      - Follow log output"
    echo "  --tail N - Show last N lines"
    echo ""
    echo "Examples:"
    echo "  ./docker-logs.sh nginx -f"
    echo "  ./docker-logs.sh php --tail 100"
    echo "  ./docker-logs.sh all -f"
    exit 1
fi

SERVICE=$1
shift

case $SERVICE in
    smtp)
        $DOCKER_CMD logs "$@" $SMTP_CONTAINER
        ;;
    php)
        $DOCKER_CMD logs "$@" $PHP_CONTAINER
        ;;
    nginx)
        $DOCKER_CMD logs "$@" $NGINX_CONTAINER
        ;;
    mysql)
        $DOCKER_CMD logs "$@" $MYSQL_CONTAINER
        ;;
    all)
        echo "=== Showing logs from all containers ==="
        echo ""
        echo "--- SMTP Logs ---"
        $DOCKER_CMD logs --tail 20 $SMTP_CONTAINER 2>&1 || true
        echo ""
        echo "--- PHP Logs ---"
        $DOCKER_CMD logs --tail 20 $PHP_CONTAINER 2>&1 || true
        echo ""
        echo "--- NGINX Logs ---"
        $DOCKER_CMD logs --tail 20 $NGINX_CONTAINER 2>&1 || true
        echo ""
        echo "--- MySQL Logs ---"
        $DOCKER_CMD logs --tail 20 $MYSQL_CONTAINER 2>&1 || true
        ;;
    *)
        echo "Unknown service: $SERVICE"
        echo "Run without arguments to see usage."
        exit 1
        ;;
esac
