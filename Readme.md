# HotCRP Docker Compose Setup

Complete Docker-based deployment for HotCRP (conference management system). This is a fork from [hotcrp-docker-compose](https://github.com/Bramas/hotcrp-docker-compose)

## What's Included

- HotCRP application (PHP)
- MySQL 8.0.26 database
- Nginx web server
- SMTP server (MailHog for testing or production SMTP)

## Deployment Options

### Option 1: Ansible Deployment (Recommended for Production)

For automated deployment to remote servers using Ansible, see the **[Ansible Deployment Guide](ansible/README.md)**.

Benefits:
- Automated installation of Docker and dependencies
- Idempotent deployment (safe to run multiple times)
- Easy updates and rollbacks
- Built-in backup and restore playbooks

Quick start:
```bash
cd ansible
# Edit inventory.ini and vars.yml with your settings
ansible-playbook -i inventory.ini deploy.yml
```

### Option 2: Manual Deployment (Development/Testing)

For local development or manual server setup, follow the instructions below.

## Quick Start (Development/Testing)

### 1. Clone this repository
```bash
git clone https://github.com/Bramas/hotcrp-docker-compose
cd hotcrp-docker-compose
```

### 2. Clone the HotCRP application
```bash
git clone https://github.com/kohler/hotcrp app
```

### 3. Configure environment variables
Copy the example environment file and edit as needed:
```bash
cp .env.example .env
```

Edit `.env` and set your contact information:
```bash
HOTCRP_EMAIL_FROM=contact@example.com
HOTCRP_EMAIL_CONTACT=contact@example.com
HOTCRP_CONTACT_NAME=Chairs
```

**For development/testing**: Use MailHog (already configured in `docker-compose.yaml`)
- No SMTP credentials needed
- View all emails at http://localhost:9002

**For production**: Uncomment and configure SMTP settings in `.env`:
```bash
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SERVER_HOSTNAME=your-domain.com
```

Then in `docker-compose.yaml`, comment out the MailHog service and uncomment the production SMTP service.

### 4. Start Docker Compose
```bash
docker-compose up -d
```

Wait a few seconds for all containers to start, then verify they're running:
```bash
docker ps
```

### 5. Initialize the database
```bash
docker-compose exec -T mysql /bin/sh -c "echo 'ok\nhotcrp\nhotcrppwd\nn\nY\n' | sh /srv/www/api/lib/createdb.sh --user=root --password=root"
```

### 6. Copy the HotCRP configuration
```bash
mv hotcrp-options.php app/conf/options.php
```

### 7. Access HotCRP
Open your browser and navigate to:
- **HotCRP**: http://localhost:9001
- **MailHog** (email viewer): http://localhost:9002

### 8. Create admin account
Register your first account at http://localhost:9001 - it will automatically become the administrator.

If using MailHog, check http://localhost:9002 for the verification email.



## Restarting Services

Restart all services:
```bash
docker-compose restart
```

Restart specific service:
```bash
docker-compose restart php
docker-compose restart nginx
docker-compose restart smtp
```

After changing `docker-compose.yaml` or `.env`:
```bash
docker-compose down && docker-compose up -d
```





## Complete Teardown/Destruction


### Stop containers (preserves data)
```bash
docker-compose down
```

### Stop and remove all data (WARNING: destroys database)
```bash
docker-compose down
rm -rf dbdata/
rm -rf logs/
rm -rf mail-spool/
```

### Complete cleanup (removes everything including the app)
```bash
docker-compose down
rm -rf app/
rm -rf dbdata/
rm -rf logs/
rm -rf mail-spool/
docker system prune -a  # Remove unused Docker images
```



## More options

* If you want to print the deadline in another timezone (default is HST), edit `docker/php/php.conf` (need to restart) (list of php timezones: https://www.php.net/manual/en/timezones.php)
* To change the port, you can edit `docker-compose.yaml` (need to restart)
* You can change more options in the hotcrp config file: `app/conf/options.php` (no need to restart)
* You can change or add custom php.ini options in `docker/php/php.conf` (need to restart)
* You can change or add custom nginx options in `docker/nginx/default.conf` (need to restart)


## Backups and Restore

Perform a backup:
```
docker-compose exec -T mysql mysqldump -uhotcrp -photcrppwd hotcrp > backup.sql
```

To restore:
```
docker-compose exec -T mysql mysql -uhotcrp -photcrppwd hotcrp < backup.sql
```

### Backup to S3
configure aws cli with your credentials:
```
docker run --rm -it -v aws:/root/.aws -v $(pwd):/aws amazon/aws-cli configure
```

then run the following when you want to do a backup:
```
sh s3-backup.sh
```



## Update Hotcrp
As said in the hotcrp readme, you can update your hotcrp installation just by running `git pull` inside the app folder.


## Open bash terminal inside a container

```
docker-compose exec php /bin/bash
```


```
docker-compose exec mysql /bin/bash
```
particularly useful if you want to run mysql cli `mysql -proot`
