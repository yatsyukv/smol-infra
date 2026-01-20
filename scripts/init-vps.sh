#!/bin/bash
set -euo pipefail

# smol-infra VPS Initialization Script
# Run this on a fresh Ubuntu 22.04/24.04 VPS

echo "=== smol-infra VPS Setup ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./init-vps.sh)"
    exit 1
fi

# Check Ubuntu version
. /etc/os-release
if [[ "$ID" != "ubuntu" ]] || [[ ! "$VERSION_ID" =~ ^(22|24) ]]; then
    echo "Warning: This script is tested on Ubuntu 22.04/24.04"
    echo "Current OS: $PRETTY_NAME"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ">>> Updating system packages..."
apt-get update
apt-get upgrade -y

echo ">>> Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    ufw \
    fail2ban \
    htop \
    unzip

echo ">>> Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 3000/tcp  # Dokploy UI
ufw --force enable
ufw status verbose

echo ">>> Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo ">>> Setting up swap (if needed)..."
if [ ! -f /swapfile ]; then
    # Create 2GB swap if less than 4GB RAM
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_RAM" -lt 4096 ]; then
        echo "Creating 2GB swap file..."
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
fi

echo ">>> Installing Dokploy..."
curl -sSL https://dokploy.com/install.sh | sh

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Access Dokploy at http://$(hostname -I | awk '{print $1}'):3000"
echo "2. Complete the Dokploy setup wizard"
echo "3. Configure your DNS records"
echo "4. Deploy GlitchTip and Metabase via Docker Compose"
echo ""
echo "See docs/setup-guide.md for detailed instructions"
