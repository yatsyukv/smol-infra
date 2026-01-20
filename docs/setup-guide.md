# smol-infra Setup Guide

Step-by-step guide for deploying the infrastructure stack.

## Prerequisites

- VPS with 8GB+ RAM, 4 cores (Ubuntu 22.04 or 24.04)
- Domain name with DNS access
- SSH access with key-based authentication

## Phase 1: VPS Setup

### 1.1 Provision VPS

Recommended providers:
- Hetzner Cloud (best value)
- DigitalOcean
- Linode
- Vultr

Minimum specs:
- 8GB RAM
- 4 vCPUs
- 80GB SSD
- Ubuntu 22.04 or 24.04

### 1.2 Configure DNS

Create A records pointing to your VPS IP:

```
yourdomain.com        → VPS_IP
errors.yourdomain.com → VPS_IP
analytics.yourdomain.com → VPS_IP
```

DNS propagation can take up to 48 hours, but usually completes within minutes.

### 1.3 Run Initialization Script

SSH into your VPS and run:

```bash
# Download the init script
curl -O https://raw.githubusercontent.com/YOUR_REPO/smol-infra/main/scripts/init-vps.sh

# Or clone the repo
git clone https://github.com/YOUR_REPO/smol-infra.git
cd smol-infra

# Run the init script
sudo ./scripts/init-vps.sh
```

This script will:
- Update system packages
- Install essential tools
- Configure firewall (ports 80, 443, 3000)
- Set up fail2ban
- Create swap if needed
- Install Dokploy

### 1.4 Complete Dokploy Setup

1. Access Dokploy at `http://YOUR_VPS_IP:3000`
2. Create admin account
3. Configure server settings

## Phase 2: Deploy GlitchTip

### 2.1 Create Project in Dokploy

1. In Dokploy UI, click **Create Project**
2. Name it "glitchtip"
3. Click **Create Service** → **Compose**
4. Name it "glitchtip-stack"

### 2.2 Configure Compose

Copy the contents of `observability/glitchtip/docker-compose.yml` into the Compose editor.

### 2.3 Set Environment Variables

In Dokploy, go to **Environment** tab and add:

| Variable | Value | Notes |
|----------|-------|-------|
| `SECRET_KEY` | (generate) | Run `openssl rand -hex 32` |
| `DB_PASSWORD` | (generate) | Strong password for PostgreSQL |
| `GLITCHTIP_DOMAIN` | `errors.yourdomain.com` | Your subdomain |
| `EMAIL_URL` | `smtp://...` | Optional, for notifications |
| `DEFAULT_FROM_EMAIL` | `noreply@yourdomain.com` | Optional |

### 2.4 Configure Domain

1. Go to **Domains** tab
2. Add domain: `errors.yourdomain.com`
3. Enable **HTTPS** (Let's Encrypt)
4. Select the `web` service

### 2.5 Deploy

Click **Deploy**. Wait for all containers to start.

### 2.6 Initial Setup

1. Visit `https://errors.yourdomain.com`
2. Create your admin account
3. Create an organization
4. Create a project for each application you want to monitor

### 2.7 Get DSN

For each project:
1. Go to **Settings** → **Client Keys (DSN)**
2. Copy the DSN URL
3. Add as `SENTRY_DSN` environment variable to your applications

## Phase 3: Deploy Metabase

### 3.1 Create Project in Dokploy

1. In Dokploy UI, click **Create Project**
2. Name it "metabase"
3. Click **Create Service** → **Compose**
4. Name it "metabase-stack"

### 3.2 Configure Compose

Copy the contents of `observability/metabase/docker-compose.yml` into the Compose editor.

### 3.3 Set Environment Variables

| Variable | Value | Notes |
|----------|-------|-------|
| `MB_DB_PASSWORD` | (generate) | Strong password for PostgreSQL |
| `METABASE_DOMAIN` | `analytics.yourdomain.com` | Your subdomain |
| `MB_SITE_NAME` | `Analytics` | Optional, display name |

### 3.4 Configure Domain

1. Go to **Domains** tab
2. Add domain: `analytics.yourdomain.com`
3. Enable **HTTPS** (Let's Encrypt)
4. Select the `metabase` service

### 3.5 Deploy

Click **Deploy**. Wait for containers to start (Metabase takes a few minutes on first boot).

### 3.6 Initial Setup

1. Visit `https://analytics.yourdomain.com`
2. Complete the setup wizard
3. Create admin account
4. Skip adding a database initially (or add your app database)

### 3.7 Connect Data Sources

To connect Metabase to your application databases:

1. Go to **Admin** → **Databases** → **Add database**
2. For databases in the same Dokploy network, use the container name as host
3. Create read-only database users for security:

```sql
-- MySQL example
CREATE USER 'metabase_ro'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON your_database.* TO 'metabase_ro'@'%';
FLUSH PRIVILEGES;

-- PostgreSQL example
CREATE USER metabase_ro WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE your_database TO metabase_ro;
GRANT USAGE ON SCHEMA public TO metabase_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO metabase_ro;
```

## Phase 4: Application Integration

### 4.1 Add Sentry SDK to Applications

**Node.js:**
```bash
npm install @sentry/node
```

```javascript
const Sentry = require("@sentry/node");
Sentry.init({ dsn: process.env.SENTRY_DSN });
```

**Python:**
```bash
pip install sentry-sdk
```

```python
import sentry_sdk
sentry_sdk.init(dsn=os.environ.get("SENTRY_DSN"))
```

**PHP:**
```bash
composer require sentry/sentry
```

```php
\Sentry\init(['dsn' => getenv('SENTRY_DSN')]);
```

### 4.2 Test Error Reporting

Trigger a test error in your application:

```javascript
// Node.js
throw new Error("Test error from production");
```

Check GlitchTip to verify the error appears.

## Backups

### Configure in Dokploy

1. Go to each project → **Backups**
2. Enable scheduled backups
3. Configure retention period
4. Set backup destination (local or S3)

### Manual Backup

```bash
# Backup GlitchTip PostgreSQL
docker exec glitchtip-postgres pg_dump -U glitchtip glitchtip > glitchtip_backup.sql

# Backup Metabase PostgreSQL
docker exec metabase-postgres pg_dump -U metabase metabase > metabase_backup.sql
```

### Restore

```bash
# Restore GlitchTip
cat glitchtip_backup.sql | docker exec -i glitchtip-postgres psql -U glitchtip glitchtip

# Restore Metabase
cat metabase_backup.sql | docker exec -i metabase-postgres psql -U metabase metabase
```

## Troubleshooting

### Container won't start

Check logs in Dokploy UI or:
```bash
docker logs <container_name>
```

### Can't access service

1. Verify DNS is pointing to correct IP
2. Check Traefik logs: `docker logs dokploy-traefik`
3. Verify domain configuration in Dokploy
4. Check firewall: `sudo ufw status`

### SSL certificate issues

1. Ensure DNS is properly configured
2. Wait for propagation (check with `dig yourdomain.com`)
3. Check Traefik logs for Let's Encrypt errors
4. Verify port 80 is accessible (required for HTTP-01 challenge)

### Database connection issues

1. Verify containers are on the same network
2. Check environment variables match
3. Verify database credentials
4. Check PostgreSQL logs

## Maintenance

### Update Services

In Dokploy:
1. Go to project
2. Click **Redeploy** to pull latest images

### Monitor Resources

- Use Dokploy dashboard for container metrics
- Install `htop` for system overview
- Check disk usage: `df -h`

### Security Updates

```bash
sudo apt update && sudo apt upgrade -y
```

Reboot if kernel updates were installed.
