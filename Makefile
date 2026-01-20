.PHONY: help setup secrets validate backup-glitchtip backup-metabase backup-all clean

# Default target
help:
	@echo "smol-infra - Infrastructure Management"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Generate secrets and create .env files"
	@echo "  make secrets        - Generate and display secrets (no file write)"
	@echo "  make validate       - Validate docker-compose files"
	@echo ""
	@echo "Backups (run on VPS with running containers):"
	@echo "  make backup-glitchtip  - Backup GlitchTip PostgreSQL"
	@echo "  make backup-metabase   - Backup Metabase PostgreSQL"
	@echo "  make backup-all        - Backup all databases"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean          - Remove generated .env files"

# Setup
setup: secrets-write
	@echo ""
	@echo "Setup complete. Review .env files and update domain settings."

secrets:
	@./scripts/generate-secrets.sh

secrets-write:
	@./scripts/generate-secrets.sh --write

# Validation
validate:
	@echo "Validating GlitchTip compose..."
	@cd observability/glitchtip && docker compose config --quiet && echo "  OK"
	@echo "Validating Metabase compose..."
	@cd observability/metabase && docker compose config --quiet && echo "  OK"
	@echo ""
	@echo "All compose files are valid."

# Backups (designed to run on VPS)
BACKUP_DIR ?= ./backups
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

backup-glitchtip:
	@mkdir -p $(BACKUP_DIR)
	@echo "Backing up GlitchTip PostgreSQL..."
	docker exec $$(docker ps -qf "name=glitchtip.*postgres") \
		pg_dump -U glitchtip glitchtip | gzip > $(BACKUP_DIR)/glitchtip_$(TIMESTAMP).sql.gz
	@echo "Saved: $(BACKUP_DIR)/glitchtip_$(TIMESTAMP).sql.gz"

backup-metabase:
	@mkdir -p $(BACKUP_DIR)
	@echo "Backing up Metabase PostgreSQL..."
	docker exec $$(docker ps -qf "name=metabase.*postgres") \
		pg_dump -U metabase metabase | gzip > $(BACKUP_DIR)/metabase_$(TIMESTAMP).sql.gz
	@echo "Saved: $(BACKUP_DIR)/metabase_$(TIMESTAMP).sql.gz"

backup-all: backup-glitchtip backup-metabase
	@echo ""
	@echo "All backups complete."
	@ls -la $(BACKUP_DIR)/*.sql.gz 2>/dev/null | tail -5

# Cleanup
clean:
	@echo "Removing generated .env files..."
	@rm -f observability/glitchtip/.env
	@rm -f observability/metabase/.env
	@echo "Done."
