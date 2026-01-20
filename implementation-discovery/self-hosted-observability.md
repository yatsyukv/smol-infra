# Self-Hosted Observability Stack

## Overview

This document outlines the architecture and implementation requirements for a minimal, efficient, self-hosted observability stack for applications running in Dokploy. This stack provides error monitoring and business intelligence capabilities for containerized PHP/Node.js applications with MySQL databases.

## Solution Components

### 1. GlitchTip - Error Monitoring & Alerting

**Goal:** Replace Sentry with a lightweight, self-hosted error tracking system that maintains full SDK compatibility.

**What It Does:**
- Real-time error tracking and exception monitoring
- Performance monitoring (slow requests, database queries, transactions)
- Uptime monitoring and health checks
- Alert notifications via email/webhook

**Key Advantages:**
- **Sentry API-compatible** - Uses official Sentry SDKs (PHP, Node.js, 100+ platforms)
- **Drop-in replacement** - Only requires changing the DSN endpoint, no code changes
- **Minimal resource usage** - Runs on 1GB RAM, 1 CPU core
- **Simple architecture** - Only 4 components vs Sentry's 12+
- **Proven scale** - Can handle 1.5M events/day on a €5 VPS (2 vCPUs, 4GB RAM)

**Architecture Components:**
1. Web backend (Django-based)
2. Worker service (Celery for background tasks)
3. PostgreSQL database (version 14+)
4. Redis/Valkey (optional - can use PostgreSQL for caching/sessions)

**Resource Requirements:**
- Minimum: 256MB RAM + swap (all-in-one setup)
- Recommended: 1GB RAM, 1 CPU core
- Storage: PostgreSQL database for events and metrics

**Deployment Method:**
- Docker Compose (recommended for quick setup)
- Kubernetes/Helm (for high-traffic sites)



---

### 2. Metabase - Business Intelligence & Analytics

**Goal:** Self-hosted BI tool for analyzing application data, building dashboards, and generating business insights from MySQL/PostgreSQL databases.

**What It Does:**
- Query databases with visual builder (no SQL required)
- Create interactive dashboards
- Schedule reports and set up alerts
- Embed analytics in applications
- Ad-hoc data exploration

**Key Advantages:**
- **User-friendly** - Non-technical users can explore data
- **Visual query builder** - No SQL knowledge required (SQL editor available for power users)
- **Low resource usage** - 1GB RAM minimum
- **MySQL/PostgreSQL native support** - Perfect for PHP/Node.js apps
- **Active development** - Release every ~2 days
- **Scalable** - Handles hundreds of users on 4GB RAM

**Architecture Components:**
1. **Metabase application** - Java/Clojure application (JAR file)
2. **PostgreSQL database** - Stores Metabase application data (separate from your data sources)
3. Connects to your MySQL/PostgreSQL databases as data sources

**Resource Requirements:**
- Minimum: 1 core, 1GB RAM (solo users/small teams)
- Recommended: 1 core, 2GB RAM
- Scaling: +1 CPU + 2GB RAM per 20 concurrent users
- Single core with 4GB RAM handles hundreds of users

**Deployment Method:**
- Docker Compose (recommended)
- Java JAR file
- Kubernetes

---

## Implementation Strategy

### Phase 1: Deploy Observability Stack in Dokploy
1. **Deploy GlitchTip** as a Docker Compose application in Dokploy
   - Use Dokploy's Docker Compose deployment method
   - Configure services: web, worker, PostgreSQL, Redis
   - Set up environment variables via Dokploy UI (SECRET_KEY, DATABASE_URL, EMAIL_URL)
   - Configure domain and automatic SSL via Traefik
2. **Deploy Metabase** as a Docker Compose application in Dokploy
   - Use Dokploy's Docker Compose deployment method
   - Set up PostgreSQL database for Metabase app data
   - Configure domain and automatic SSL via Traefik

### Phase 2: Configure GlitchTip
1. Access GlitchTip web interface (configured domain)
2. Create admin user and organization
3. Create projects for each application
4. Get DSN endpoints for each project
5. Update application environment variables in Dokploy
   - Add Sentry DSN to each application's env vars
   - Redeploy applications to pick up changes
6. Test error reporting from containerized applications
7. Configure alerting rules and notification channels

### Phase 3: Configure Metabase
1. Complete Metabase initial setup wizard
2. Connect to application databases
   - Use Dokploy's internal Docker network hostnames
   - Connect to MySQL databases (accessible via service names)
   - Create read-only database users for security
3. Create sample queries and dashboards
4. Set up user accounts and permissions
5. Configure email for alerts/reports (optional)
6. Create key business dashboards (signups, revenue, activity, etc.)

### Phase 4: Integration & Operations
1. Document Dokploy deployment configurations
2. Set up backup strategies using Dokploy's backup features
3. Configure Dokploy monitoring for observability stack
4. Create runbooks for common issues
5. Train team on using Metabase for data exploration
6. Establish dashboard review and maintenance schedule

---

## Integration with Dokploy

**Dokploy Infrastructure:**
- All applications run as Docker containers managed by Dokploy
- Traefik provides reverse proxy and automatic SSL
- Docker Swarm networking enables service discovery
- Applications communicate via dokploy-network

**GlitchTip Integration:**
- Deploy GlitchTip as Dokploy application
- Configure DSN endpoints via Dokploy environment variables
- No SDK changes required (uses same Sentry SDKs)
- Applications send errors to GlitchTip container on same network
- Migration takes < 5 minutes per application via Dokploy UI

**Metabase Integration:**
- Deploy Metabase as Dokploy application
- Access application databases using Docker network hostnames
- If apps use Dokploy-managed databases, use service names
- If apps use external databases, use database host addresses
- Metabase and applications run on same Docker Swarm network

**CI/CD via Dokploy:**
- Use Dokploy's built-in Git repository integration
- Git push triggers automatic rebuild and deployment
- No separate CI/CD tool needed for this stack size

---

## Network & Security Considerations

**Dokploy Networking:**
- All services communicate via dokploy-network (Docker Swarm)
- Traefik handles all external HTTPS traffic
- Internal service-to-service communication uses Docker DNS
- Only ports 80, 443, and 3000 (Dokploy UI) exposed externally

**GlitchTip:**
- Deployed in Dokploy with dedicated domain (e.g., errors.yourdomain.com)
- Traefik provides automatic HTTPS via Let's Encrypt
- PostgreSQL and Redis only accessible within dokploy-network
- Configure Traefik labels via Dokploy UI for routing
- No external database exposure

**Metabase:**
- Deployed in Dokploy with dedicated domain (e.g., analytics.yourdomain.com)
- Traefik provides automatic HTTPS via Let's Encrypt
- Metabase PostgreSQL only accessible within dokploy-network
- Application databases accessible via Docker network or external hosts
- Use read-only database users for safety
- Session management and user authentication built-in

**Security Best Practices:**
- Use Dokploy's environment variable management for secrets
- Create read-only database users for Metabase
- Restrict Dokploy UI access (port 3000) via firewall if needed
- Enable Dokploy authentication and user management
- Regular backups via Dokploy's backup features

---

## Scaling Considerations

**GlitchTip:**
- Horizontal scaling via Docker Compose replicas in Dokploy
- Scale worker instances using Dokploy's scaling UI
- Database: PostgreSQL read replicas for high load
- Can handle 1.5M events/day on minimal VPS

**Metabase:**
- Starts small (1GB RAM, 1 core)
- Scales vertically by adjusting resource limits in Dokploy
- Single core with 4GB RAM handles hundreds of users
- Can run multiple instances for HA using Dokploy scaling

**Dokploy Infrastructure:**
- All observability tools benefit from Dokploy's container orchestration
- Easy resource allocation via Dokploy UI
- Can move services to larger VPS if needed
- Docker Swarm enables multi-node scaling if required

---

## Cost Implications

All solutions are:
- **Free and open-source** - No licensing costs
- **Self-hosted** - Only infrastructure costs (VPS hosting)
- **Minimal resource overhead** - Can run on existing Dokploy infrastructure
- **No per-event/per-user pricing** - Unlike SaaS alternatives

**Estimated Resource Usage:**
- Dokploy overhead: ~500MB RAM (Dokploy + Traefik)
- GlitchTip: 1-2GB RAM
- Metabase: 1-2GB RAM
- Application containers: Variable based on apps
- Total recommended: 8GB RAM VPS minimum

**Deployment Options:**
- **Option 1:** Deploy observability stack on same VPS as applications (8GB+ recommended)
- **Option 2:** Dedicated VPS for observability (4GB dedicated + existing app VPS)
- Both options are cost-effective compared to SaaS alternatives (Sentry, Mixpanel, etc.)

---

## Detailed Implementation Plans

### GlitchTip Implementation in Dokploy

**Prerequisites:**
- Dokploy installed and running
- Domain name or subdomain (e.g., errors.yourdomain.com)
- DNS A record pointing to your Dokploy VPS

**Step-by-Step:**

**1. Create docker-compose.yml for GlitchTip:**
```yaml
version: '3'

services:
  web:
    image: glitchtip/glitchtip:latest
    depends_on:
      - postgres
      - redis
    environment:
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgresql://glitchtip:${DB_PASSWORD}@postgres:5432/glitchtip
      REDIS_URL: redis://redis:6379/0
      EMAIL_URL: ${EMAIL_URL}
      GLITCHTIP_DOMAIN: ${GLITCHTIP_DOMAIN}
      PORT: 8000
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.glitchtip.rule=Host(`${GLITCHTIP_DOMAIN}`)"
      - "traefik.http.services.glitchtip.loadbalancer.server.port=8000"

  worker:
    image: glitchtip/glitchtip:latest
    depends_on:
      - postgres
      - redis
    environment:
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgresql://glitchtip:${DB_PASSWORD}@postgres:5432/glitchtip
      REDIS_URL: redis://redis:6379/0
    command: ./bin/run-celery-with-beat.sh

  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: glitchtip
      POSTGRES_USER: glitchtip
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
  redis-data:
```

**2. Deploy in Dokploy:**
1. Log into Dokploy UI at `http://your-server:3000`
2. Create new application: "GlitchTip"
3. Choose "Docker Compose" deployment method
4. Paste the docker-compose.yml above
5. Configure environment variables in Dokploy UI:
   - `SECRET_KEY`: Generate with `openssl rand -hex 32`
   - `DB_PASSWORD`: Secure database password
   - `EMAIL_URL`: SMTP URL (e.g., `smtp://user:pass@smtp.gmail.com:587`)
   - `GLITCHTIP_DOMAIN`: Your domain (e.g., `errors.yourdomain.com`)
6. Configure domain in Dokploy:
   - Add domain: `errors.yourdomain.com`
   - Enable SSL (automatic via Let's Encrypt)
7. Deploy the application
8. Wait for Dokploy to pull images and start services

**3. Initial Setup:**
1. Access `https://errors.yourdomain.com`
2. Create superuser account (first user is admin)
3. Create organization
4. Create project for each application
5. Get DSN endpoint for each project

**4. Configure Applications:**
1. In Dokploy, open each application
2. Add environment variable: `SENTRY_DSN=<glitchtip-dsn>`
3. Redeploy application to pick up changes
4. Install Sentry SDK if not already present (PHP: `sentry/sentry`, Node.js: `@sentry/node`)

**Testing:**
- Trigger test error: `throw new Exception('Test error');` (PHP) or `throw new Error('Test error');` (Node.js)
- Verify events appear in GlitchTip dashboard at `https://errors.yourdomain.com`

### Metabase Implementation in Dokploy

**Prerequisites:**
- Dokploy installed and running
- Domain name or subdomain (e.g., analytics.yourdomain.com)
- DNS A record pointing to your Dokploy VPS
- Access credentials for your application databases

**Step-by-Step:**

**1. Create docker-compose.yml for Metabase:**
```yaml
version: '3'
services:
  metabase:
    image: metabase/metabase:latest
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabase
      MB_DB_PORT: 5432
      MB_DB_USER: metabase
      MB_DB_PASS: ${MB_DB_PASSWORD}
      MB_DB_HOST: postgres
      MB_SITE_URL: https://${METABASE_DOMAIN}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.metabase.rule=Host(`${METABASE_DOMAIN}`)"
      - "traefik.http.services.metabase.loadbalancer.server.port=3000"
    volumes:
      - metabase-data:/metabase-data
    depends_on:
      - postgres

  postgres:
    image: postgres:14
    environment:
      POSTGRES_USER: metabase
      POSTGRES_PASSWORD: ${MB_DB_PASSWORD}
      POSTGRES_DB: metabase
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  metabase-data:
  postgres-data:
```

**2. Deploy in Dokploy:**
1. Log into Dokploy UI at `http://your-server:3000`
2. Create new application: "Metabase"
3. Choose "Docker Compose" deployment method
4. Paste the docker-compose.yml above
5. Configure environment variables in Dokploy UI:
   - `MB_DB_PASSWORD`: Secure database password
   - `METABASE_DOMAIN`: Your domain (e.g., `analytics.yourdomain.com`)
6. Configure domain in Dokploy:
   - Add domain: `analytics.yourdomain.com`
   - Enable SSL (automatic via Let's Encrypt)
7. Deploy the application
8. Wait for Dokploy to pull images and start services

**3. Initial Setup:**
- Access: `https://analytics.yourdomain.com`
- Complete setup wizard:
  - Create admin account
  - Set language and preferences
  - Skip "Add your data" (do this next)

**4. Connect to Your Application Databases:**

**For Dokploy-Managed Databases:**
- Click "Add Database" or Settings → Admin → Databases → Add database
- Database type: MySQL or PostgreSQL
- Name: "Production MySQL" (or your app name)
- Host: Use Docker service name or Dokploy database hostname
  - If database is in same Dokploy project: use service name (e.g., `mysql`, `postgres`)
  - If database is separate Dokploy app: use `<app-name>_<service-name>`
  - Check Dokploy logs or inspect container names for exact hostname
- Port: 3306 (MySQL) or 5432 (PostgreSQL)
- Database name: your_database
- Username: metabase_readonly (recommended: create read-only user)
- Password: your_password
- Click "Save"
- Metabase will scan schema and tables

**For External Databases:**
- Same process, use external host IP or domain
- Ensure firewall allows connection from Dokploy VPS

**5. Create Read-Only Database Users (Recommended):**

**MySQL:**
```sql
CREATE USER 'metabase_readonly'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT ON your_database.* TO 'metabase_readonly'@'%';
FLUSH PRIVILEGES;
```

**PostgreSQL:**
```sql
CREATE USER metabase_readonly WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE your_database TO metabase_readonly;
GRANT USAGE ON SCHEMA public TO metabase_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO metabase_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO metabase_readonly;
```

**6. Create Your First Dashboard:**

**Example: User Signups Dashboard**
1. Click "New" → Question
2. Select your database → users table
3. Summarize: Count of rows
4. Group by: Created_at (by day/week/month)
5. Visualize as line chart
6. Save as "User Signups Over Time"
7. Click "Save" → Add to new dashboard "Growth Metrics"

**Example Queries for Common Business Metrics:**

**Active Users:**
- Table: users
- Filter: last_login_at in the past 30 days
- Summarize: Count

**Revenue (if you have orders/payments table):**
- Table: orders
- Summarize: Sum of amount
- Group by: created_at (by month)
- Filter: status = 'completed'

**Conversion Funnel:**
- Create multiple questions:
  - Visitors (from analytics table)
  - Signups (from users table)
  - Paid Users (from subscriptions table)
- Add all to dashboard for comparison

**7. Set Up Users and Permissions:****
- Settings → Admin → People → Add someone
- Create groups for different access levels:
  - Analysts: Can create queries and dashboards
  - Executives: View-only access to specific dashboards
  - Developers: Full access
- Settings → Admin → Permissions
- Configure database access per group

**8. Configure Alerts (Optional):**
- Open any question/chart
- Click bell icon "Get alerts"
- Set up email alerts:
  - Daily/weekly digests
  - Threshold alerts (e.g., "Alert me if signups drop below 10/day")

**9. Schedule Reports (Optional):**
- Open dashboard
- Click "Sharing" icon
- Set up email schedule:
  - Daily/weekly/monthly
  - Choose recipients
  - Attach as PDF or link

**10. Production Considerations:**
- HTTPS already configured via Dokploy/Traefik
- `MB_SITE_URL` set via environment variables
- Enable embedding if needed: Add `MB_EMBEDDING_SECRET_KEY` environment variable
- Use Dokploy's backup features for Metabase PostgreSQL database
- Monitor resource usage via Dokploy monitoring dashboard
- Set resource limits in Dokploy if needed
- Create documentation for your team

**11. Maintenance:**
- Backup via Dokploy's backup features
- Update Metabase: Use Dokploy's rebuild/redeploy feature
- Review and archive unused questions/dashboards
- Monitor query performance and optimize slow queries
- Check Dokploy logs for any issues

**Common Issues & Solutions:**

**Metabase uses too much memory:**
- Increase JVM heap: `JAVA_OPTS: "-Xmx2g"` in environment

**Queries are slow:**
- Add database indexes on commonly queried columns
- Use Metabase's query caching
- Consider database read replicas for analytics

**Can't connect to database:**
- Verify database host is accessible from Metabase container
- Check firewall rules
- Verify database credentials
- For Dokploy, use Docker service names or check container hostnames
- Verify services are on dokploy-network

---

## References

### GlitchTip
- Official Site: https://glitchtip.com/
- Installation Guide: https://glitchtip.com/documentation/install/
- Docker Setup: https://dev.to/ruanbekker/setup-glitchtip-error-monitoring-on-docker-358
- Comparison: https://www.bugsink.com/blog/glitchtip-vs-sentry-vs-bugsink/

### Dokploy
- GitHub Repository: https://github.com/Dokploy/dokploy
- Official Documentation: https://docs.dokploy.com/
- Docker Compose Guide: https://docs.dokploy.com/docs/core/architecture


### Metabase
- Official Site: https://www.metabase.com/
- GitHub Repository: https://github.com/metabase/metabase
- Documentation: https://www.metabase.com/docs/latest/
- Running in Production: https://www.metabase.com/learn/metabase-basics/administration/administration-and-operation/metabase-in-production
- Self-Hosting Guide: https://dev.to/krusenas/self-hosted-business-intelligence-with-metabase-3php
