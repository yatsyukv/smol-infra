#!/bin/bash
set -euo pipefail

# Generate secrets for smol-infra services
# Usage: ./generate-secrets.sh [--write]
#   --write: Write secrets directly to .env files (creates from .env.example)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

WRITE_FILES=false
if [[ "${1:-}" == "--write" ]]; then
    WRITE_FILES=true
fi

# Generate secure random strings
generate_secret() {
    openssl rand -hex 32
}

generate_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 24
}

echo "=== smol-infra Secret Generator ==="
echo ""

# Generate all secrets
GLITCHTIP_SECRET_KEY=$(generate_secret)
GLITCHTIP_DB_PASSWORD=$(generate_password)
METABASE_DB_PASSWORD=$(generate_password)

if [[ "$WRITE_FILES" == true ]]; then
    echo "Writing secrets to .env files..."
    echo ""

    # GlitchTip
    GLITCHTIP_DIR="$ROOT_DIR/observability/glitchtip"
    if [[ -f "$GLITCHTIP_DIR/.env.example" ]]; then
        cp "$GLITCHTIP_DIR/.env.example" "$GLITCHTIP_DIR/.env"
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$GLITCHTIP_SECRET_KEY/" "$GLITCHTIP_DIR/.env"
            sed -i '' "s/DB_PASSWORD=.*/DB_PASSWORD=$GLITCHTIP_DB_PASSWORD/" "$GLITCHTIP_DIR/.env"
        else
            sed -i "s/SECRET_KEY=.*/SECRET_KEY=$GLITCHTIP_SECRET_KEY/" "$GLITCHTIP_DIR/.env"
            sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$GLITCHTIP_DB_PASSWORD/" "$GLITCHTIP_DIR/.env"
        fi
        echo "Created: $GLITCHTIP_DIR/.env"
    fi

    # Metabase
    METABASE_DIR="$ROOT_DIR/observability/metabase"
    if [[ -f "$METABASE_DIR/.env.example" ]]; then
        cp "$METABASE_DIR/.env.example" "$METABASE_DIR/.env"
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/MB_DB_PASSWORD=.*/MB_DB_PASSWORD=$METABASE_DB_PASSWORD/" "$METABASE_DIR/.env"
        else
            sed -i "s/MB_DB_PASSWORD=.*/MB_DB_PASSWORD=$METABASE_DB_PASSWORD/" "$METABASE_DIR/.env"
        fi
        echo "Created: $METABASE_DIR/.env"
    fi

    echo ""
    echo "Done! Review and update domain settings in each .env file."
else
    echo "GlitchTip secrets:"
    echo "  SECRET_KEY=$GLITCHTIP_SECRET_KEY"
    echo "  DB_PASSWORD=$GLITCHTIP_DB_PASSWORD"
    echo ""
    echo "Metabase secrets:"
    echo "  MB_DB_PASSWORD=$METABASE_DB_PASSWORD"
    echo ""
    echo "To write these to .env files automatically, run:"
    echo "  $0 --write"
fi
