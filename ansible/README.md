# HotCRP Ansible Deployment (Minimal)

Bare minimum Ansible setup to start HotCRP docker-compose on remote servers.

## Prerequisites

- Ansible installed on your local machine
- Docker and Docker Compose installed on target server(s)
- HotCRP files already deployed on server at `/opt/hotcrp`
- SSH access to target server(s)

## Quick Start

### 1. Edit inventory file

Update `inventory.ini` with your server details:

```ini
[hotcrp_servers]
myserver ansible_host=192.168.1.100 ansible_user=ubuntu
```

### 2. Test connection

```bash
ansible -i inventory.ini hotcrp_servers -m ping
```

### 3. Start services

```bash
ansible-playbook -i inventory.ini deploy.yml
```

## What it does

Simply runs `docker-compose up -d` in `/opt/hotcrp` on your server(s).

## Customize

If your HotCRP is installed in a different directory, edit `deploy.yml` and change:

```yaml
chdir: /opt/hotcrp
```

to your installation path.

## Multiple Servers

Add more servers to `inventory.ini`:

```ini
[hotcrp_servers]
server1 ansible_host=192.168.1.10 ansible_user=ubuntu
server2 ansible_host=192.168.1.20 ansible_user=ubuntu
server3 ansible_host=192.168.1.30 ansible_user=ubuntu
```

Then deploy to all:
```bash
ansible-playbook -i inventory.ini deploy.yml
```

Or deploy to specific server:
```bash
ansible-playbook -i inventory.ini deploy.yml --limit server1
```
