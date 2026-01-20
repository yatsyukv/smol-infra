# Self-Hosted Infrastructure Migration Plan

## Project Overview

**Goal:** Migrate multiple small web projects from traditional NGINX-based VPS hosting to a containerized, modern infrastructure using Dokploy.

**Current State:**
- Multiple web projects running on single VPS with NGINX reverse proxy
- Tech stack: PHP, Node.js, Python, MySQL
- Domain configuration:
  - site1.mydomain.com
  - site2.mydomain.com
  - anotherdomain.com
- Manual server runtime/updates management

**Target State:**
- Containerized applications managed through Dokploy web UI
- Automated SSL certificate management
- Simplified deployment and scaling
- Reduced maintenance overhead
- Modern DevOps workflow

---

## Solution: Dokploy

### What is Dokploy?

Dokploy is a free, open-source, self-hosted Platform as a Service (PaaS) that simplifies deployment and management of Docker applications. It serves as an alternative to Heroku, Vercel, and Netlify for self-hosted environments.

**Key Characteristics:**
- **Repository:** https://github.com/Dokploy/dokploy
- **Stars:** 29,205+ (January 2026)
- **Active Development:** Last updated January 16, 2026
- **Contributors:** 200+
- **Community Sentiment:** Extremely positive ("looks like a million-dollar product")

### Why Dokploy?

1. **Resource Efficient** - Uses only 0.8-1.5% CPU at idle (vs competitors at 6-7%)
2. **No Kubernetes Complexity** - Uses Docker Swarm instead of K8s
3. **Modern Web UI** - Clean, intuitive interface for managing containers
4. **Built-in Reverse Proxy** - Traefik with automatic SSL (Let's Encrypt)
5. **Fast Deployments** - 5-second incremental, 40-second full rebuilds
6. **Docker-Native** - Excellent Docker Compose support
7. **Single VPS Optimized** - Perfect for small to medium workloads

---

## Technical Architecture

### Core Components

```
┌─────────────────────────────────────────┐
│         Internet Traffic                │
│      (HTTP/HTTPS on ports 80/443)       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Traefik Reverse Proxy           │
│  - Automatic SSL (Let's Encrypt)        │
│  - Domain routing                       │
│  - Load balancing                       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Docker Swarm Network            │
│        (dokploy-network)                │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┬─────────────┐
       ▼                ▼             ▼
┌──────────┐    ┌──────────┐   ┌──────────┐
│   App 1  │    │   App 2  │   │  App 3   │
│  (PHP)   │    │ (Node.js)│   │ (Python) │
└──────────┘    └──────────┘   └──────────┘
       │                │             │
       └────────┬───────┴─────────────┘
                ▼
       ┌─────────────────┐
       │  MySQL Database │
       └─────────────────┘
```

### Component Details

**1. Dokploy Control Panel**
- Web interface on port 3000
- Manages all Docker containers
- Configuration and monitoring dashboard

**2. Traefik (Reverse Proxy)**
- Automatic service discovery
- SSL certificate management
- HTTP/HTTPS routing
- Configured via Docker labels

**3. Docker Swarm**
- Lightweight orchestration (not K8s)
- Single-node mode for VPS
- Can scale to multi-node if needed
- Automatic service discovery

**4. Application Containers**
- Each project runs in isolated container(s)
- Supports: Docker, Docker Compose, Nixpacks, Heroku buildpacks
- Automatic health checks

**5. Database Containers**
- MySQL, PostgreSQL, MongoDB, MariaDB, Redis supported
- Automatic backups to external storage
- Volume persistence

---

## System Requirements

### Minimum Specifications
- **RAM:** 2GB minimum (4GB+ recommended)
- **Disk:** 30GB minimum
- **CPU:** 1-2 cores (more for better performance)
- **OS:** Ubuntu 20.04+ (officially supported)
  - Also tested on: Debian, CentOS, Fedora
  - Not supported: Windows, macOS as host

### Required Ports
- **80** - HTTP traffic (Traefik)
- **443** - HTTPS traffic (Traefik)
- **3000** - Dokploy web interface

### Network Requirements
- Static IP or domain name
- DNS access to configure A/CNAME records
- Root/sudo access to VPS

---

## Installation Overview

### Quick Install (Recommended)
```bash
curl -sSL https://dokploy.com/install.sh | sh
```

**What the script does:**
1. Installs Docker Engine (if not present)
2. Initializes Docker Swarm mode
3. Creates dokploy-network
4. Pulls Dokploy Docker images
5. Deploys Traefik reverse proxy
6. Starts Dokploy web interface

**Installation Time:** 5-10 minutes on typical VPS

### Post-Installation
1. Access web interface at `http://YOUR_VPS_IP:3000`
2. Complete initial setup wizard
3. Configure DNS records for domains
4. Deploy first application

---

## Deployment Methods

Dokploy supports multiple deployment approaches:

### 1. Docker Image
Deploy pre-built Docker images from registries (Docker Hub, GHCR, private registries)

**Use case:** Production-ready images, microservices

### 2. Docker Compose
Deploy multi-container applications using docker-compose.yml

**Use case:** Complex applications with multiple services (perfect for current setup)

**Example structure:**
```yaml
services:
  web:
    image: php:8.2-apache
    volumes:
      - ./app:/var/www/html
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
```

### 3. Git Repository
Connect GitHub/GitLab/Bitbucket/Gitea repositories for automatic deployments

**Use case:** Continuous deployment from Git

### 4. Dockerfile
Build custom images from Dockerfile

**Use case:** Custom build requirements

### 5. Nixpacks
Automatic buildpack detection (similar to Heroku)

**Use case:** Simple Node.js, Python, Ruby apps

---

## Migration Strategy

### Current NGINX Setup → Dokploy Equivalent

| Current Setup | Dokploy Equivalent |
|--------------|-------------------|
| NGINX config files | Traefik automatic routing |
| Manual SSL with certbot | Automatic Let's Encrypt SSL |
| systemd service files | Docker container management |
| Manual app updates | Git-based or manual redeploy |
| Direct file system access | Docker volumes |
| Manual subdomain routing | Automatic domain routing via UI |

### Domain Mapping
```
site1.mydomain.com  →  Dokploy App 1 (PHP container)
site2.mydomain.com  →  Dokploy App 2 (Node container)
anotherdomain.com   →  Dokploy App 3 (Python container)
```

---

## Key Features for Implementation

### 1. Multi-Database Support
- Create and manage databases through UI
- Automatic backup scheduling
- External storage integration (S3, etc.)

### 2. Environment Variables
- Secure management through UI
- Per-application configuration
- No hard-coded secrets

### 3. Domain & SSL Management
- Add multiple domains per application
- Automatic SSL certificate issuance
- Certificate auto-renewal
- Support for wildcard certificates

### 4. Monitoring & Logs
- Real-time container logs
- CPU, memory, network usage graphs
- Container health status
- Build/deployment history

### 5. Manual Scaling
- Scale containers up/down via UI slider
- Resource limit configuration
- Multi-replica support (Docker Swarm)

### 6. One-Click Services
- Pre-configured templates for common services
- Easy database deployment
- Monitoring tools (if needed)

---

## Resource Consumption

### Dokploy Overhead (Based on Real-World Testing)
- **Idle CPU:** 0.8-1.5%
- **Memory:** ~400-500 MB
- **Disk:** ~2 GB for Dokploy + Traefik

### Per-Application Overhead
Minimal Docker overhead compared to native processes:
- Small PHP app: +50-100 MB RAM
- Node.js app: +100-200 MB RAM
- Python app: +100-200 MB RAM

**Trade-off:** Slightly higher memory usage for massive operational benefits

---

## Advantages Over Current Setup

### Operational Benefits
1. **Simplified Updates** - Pull new image or redeploy from Git
2. **Environment Isolation** - Apps can't conflict with each other
3. **Easy Rollback** - Previous container versions available
4. **Zero-Downtime Deploys** - Rolling updates with health checks
5. **Portable Infrastructure** - Move entire setup to new VPS easily

### Developer Experience
1. **Web UI Management** - No SSH needed for routine tasks
2. **Environment Parity** - Same Docker setup locally and in production
3. **Quick Experimentation** - Spin up/down apps in seconds
4. **Clear Resource Visibility** - See what each app consumes

### Security Benefits
1. **Container Isolation** - Apps run in separate namespaces
2. **Automatic SSL** - No expired certificates
3. **Secrets Management** - Environment variables not in code
4. **Update Simplification** - Update base images easily

---

## Potential Challenges & Considerations

### Learning Curve
- Need to understand Docker basics
- Docker Compose for multi-service apps
- Traefik label configuration for advanced routing

### Migration Complexity
- Applications need to be containerized
- Database migration requires careful planning
- DNS cutover needs coordination
- Potential downtime during migration

### Resource Overhead
- Docker adds ~10-15% memory overhead
- Each container needs base system libraries
- Disk space increases with images/volumes

### Debugging Changes
- Logs are in containers (not /var/log)
- Need to use `docker logs` or Dokploy UI
- File access requires `docker exec` or volumes

---

## Success Criteria

### Must-Have
- [ ] All current sites accessible via original domains
- [ ] SSL certificates working on all domains
- [ ] Zero permanent data loss during migration
- [ ] Comparable or better performance
- [ ] Ability to deploy updates via web UI

### Should-Have
- [ ] Faster deployment times than current setup
- [ ] Better resource visibility and monitoring
- [ ] Simplified backup/restore process
- [ ] Clear rollback procedure

### Nice-to-Have
- [ ] Git-based automatic deployments
- [ ] Staging environments for testing
- [ ] Monitoring/alerting setup
- [ ] Automated database backups

---

## Next Steps for Implementation

1. **Preparation Phase**
   - Provision new VPS or snapshot current one
   - Document all current NGINX configurations
   - Audit all applications and their dependencies
   - Create Docker Compose files for each project

2. **Installation Phase**
   - Install Dokploy on VPS
   - Configure DNS for testing subdomain
   - Verify Traefik is working
   - Test with simple "hello world" app

3. **Migration Phase**
   - Deploy first application (least critical)
   - Migrate databases with backups
   - Update DNS records
   - Monitor for issues
   - Repeat for remaining applications

4. **Validation Phase**
   - Verify all sites are accessible
   - Test SSL certificates
   - Performance testing
   - Document new deployment procedures

5. **Optimization Phase**
   - Fine-tune resource limits
   - Set up monitoring/alerting
   - Configure automated backups
   - Create disaster recovery plan

---

## References & Resources

### Official Documentation
- Dokploy Docs: https://docs.dokploy.com/
- Dokploy GitHub: https://github.com/Dokploy/dokploy
- Traefik Docs: https://doc.traefik.io/traefik/

### Community Resources
- Hetzner Setup Guide: https://community.hetzner.com/tutorials/setup-dokploy-on-your-vps/
- Comparison Analysis: https://docs.dokploy.com/docs/core/comparison

### Architecture References
- Dokploy Architecture: https://docs.dokploy.com/docs/core/architecture
- Docker Swarm Documentation: https://docs.docker.com/engine/swarm/

---

## Document Version
- **Created:** January 2026
- **Last Updated:** January 2026
- **Status:** Planning/Pre-Implementation
