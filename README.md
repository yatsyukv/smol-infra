# smol-infra

Self-hosted containerized infrastructure using Dokploy with observability tools.

## Overview

This repository contains Docker Compose configurations and setup scripts for deploying:

- **Dokploy** - Container orchestration and deployment platform
- **GlitchTip** - Error monitoring (Sentry-compatible)
- **Metabase** - Business intelligence and analytics

## Requirements

- VPS with 8GB+ RAM, 4 cores (Ubuntu 22.04/24.04)
- Domain with DNS access
- Ports 80, 443, 3000 open

## Quick Start

1. **Provision VPS and install Dokploy:**
   ```bash
   curl -sSL https://dokploy.com/install.sh | sh
   ```

2. **Access Dokploy UI** at `http://YOUR_VPS_IP:3000`

3. **Deploy observability stack** via Dokploy Docker Compose:
   - Import `observability/glitchtip/docker-compose.yml`
   - Import `observability/metabase/docker-compose.yml`

See [docs/setup-guide.md](docs/setup-guide.md) for detailed instructions.

## Directory Structure

```
smol-infra/
├── README.md                           # This file
├── observability/
│   ├── glitchtip/
│   │   ├── docker-compose.yml          # GlitchTip stack
│   │   └── .env.example                # Environment template
│   └── metabase/
│       ├── docker-compose.yml          # Metabase stack
│       └── .env.example                # Environment template
├── scripts/
│   └── init-vps.sh                     # VPS setup script
└── docs/
    └── setup-guide.md                  # Deployment guide
```

## Components

### GlitchTip (Error Monitoring)

Sentry-compatible error tracking. Collects exceptions and errors from your applications.

- Web UI for error management
- Celery worker for background processing
- PostgreSQL for data storage
- Redis for task queue

### Metabase (Analytics)

Business intelligence platform for querying and visualizing data.

- Connect to your application databases
- Build dashboards and reports
- Schedule automated reports

## Configuration

Each service has a `.env.example` file. Copy to `.env` and configure:

```bash
cd observability/glitchtip
cp .env.example .env
# Edit .env with your values
```

## Deployment via Dokploy

1. Create a new "Compose" project in Dokploy
2. Paste the docker-compose.yml contents
3. Set environment variables in the Dokploy UI
4. Configure domain and enable SSL
5. Deploy

## Backups

Configure backups through Dokploy UI:
- Database volumes are persisted
- Set up scheduled backups to S3 or external storage
- Test restore procedures regularly

## License

MIT
