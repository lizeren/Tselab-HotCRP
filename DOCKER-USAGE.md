# Docker Usage Guide (Without Docker Compose)

Since you cannot use `docker-compose`, I've created shell scripts that use plain Docker commands to manage your HotCRP setup.

## Available Scripts

### 1. `docker-run.sh` - Start all services
```bash
./docker-run.sh
```

This script will:
- Create a Docker network for container communication
- Build the PHP image
- Stop and remove any existing containers
- Start all services (SMTP, PHP, NGINX, MySQL)

**Services started:**
- **SMTP (MailHog)**: Available at http://localhost:9002
- **HotCRP Web**: Available at http://localhost:9001

### 2. `docker-stop.sh` - Stop all services
```bash
./docker-stop.sh
```

This script will:
- Stop all running containers
- Remove all containers
- Preserve the network and data volumes

### 3. `docker-logs.sh` - View container logs
```bash
./docker-logs.sh [service] [options]
```

**Examples:**
```bash
# View NGINX logs
./docker-logs.sh nginx

# Follow PHP logs in real-time
./docker-logs.sh php -f

# View last 50 lines of MySQL logs
./docker-logs.sh mysql --tail 50

# View all logs together
./docker-logs.sh all
```

**Available services:** smtp, php, nginx, mysql, all

## Container Names

The containers are named as follows:
- `hotcrp-smtp` - SMTP/MailHog service
- `hotcrp-php` - PHP-FPM service
- `hotcrp-nginx` - NGINX web server
- `hotcrp-mysql` - MySQL database

## Common Docker Commands

### View running containers
```bash
docker ps
```

### Execute commands in a container
```bash
docker exec -it hotcrp-php bash
docker exec -it hotcrp-mysql mysql -u hotcrp -photcrppwd hotcrp
```

### View logs manually
```bash
docker logs hotcrp-nginx
docker logs -f hotcrp-php  # Follow logs
```

### Restart a specific container
```bash
docker restart hotcrp-nginx
```

### Inspect a container
```bash
docker inspect hotcrp-php
```

### View network details
```bash
docker network inspect hotcrp-network
```

## Troubleshooting

### Containers won't start
Check if ports 9001 and 9002 are already in use:
```bash
sudo netstat -tulpn | grep -E ':(9001|9002)'
```

### Rebuild PHP image
If you make changes to the PHP Dockerfile or configuration:
```bash
docker build -t hotcrp-php:latest -f docker/php/Dockerfile docker/php
./docker-run.sh
```

### Clean up everything (including volumes)
```bash
./docker-stop.sh
docker network rm hotcrp-network
rm -rf ./dbdata  # WARNING: This deletes your database!
```

### View resource usage
```bash
docker stats hotcrp-smtp hotcrp-php hotcrp-nginx hotcrp-mysql
```

## Differences from Docker Compose

1. **No automatic dependency management**: The scripts start containers in the correct order
2. **Manual network creation**: A custom bridge network is created for inter-container communication
3. **Container names**: Fixed names are used instead of project-prefixed names
4. **Restart behavior**: All containers are set to `--restart always`

## Environment Variables

Make sure your `.env` file exists in the project root with the following variables:
```
HOTCRP_PAPER_SITE=your_paper_site
HOTCRP_CONTACT_NAME=your_contact_name
HOTCRP_EMAIL_CONTACT=your_email_contact
HOTCRP_EMAIL_FROM=your_email_from
```

The `docker-run.sh` script will automatically load these variables.
