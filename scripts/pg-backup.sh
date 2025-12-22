#!/bin/bash
set -euo pipefail
BACKUP_DIR=${1:-./backups}
mkdir -p "$BACKUP_DIR"
ts=$(date +"%Y%m%d-%H%M%S")
docker compose exec -T postgres pg_dump -U postgres babushka > "$BACKUP_DIR/babushka-$ts.sql"
echo "Backup saved to $BACKUP_DIR/babushka-$ts.sql"
