#!/usr/bin/env bash
set -euo pipefail

# Usage: ./backup.sh <container> <DBName> [WindowsOutDir]
# Example: ./backup.sh sql2 Martin /mnt/c/sqlbackups

CONTAINER="${1:-sql2}"
DB="${2:-}"
WIN_DIR="${3:-/mnt/c/sqlbackups}"

if [[ -z "$DB" ]]; then
  echo "Usage: $0 <container> <DBName> [WindowsOutDir]"
  exit 1
fi

# 1) Where to save on Windows
mkdir -p "$WIN_DIR"

# 2) Inside-container temp dir for backups
docker exec "$CONTAINER" bash -lc 'mkdir -p /var/opt/mssql/backups'

# 3) Run the backup inside the container
STAMP=$(date +%Y%m%d_%H%M%S)
IN_CONTAINER="/var/opt/mssql/backups/${DB}_${STAMP}.bak"

docker exec "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'MyPassw0rd!' -C \
  -Q "BACKUP DATABASE [$DB] TO DISK = N'$IN_CONTAINER' WITH INIT, FORMAT"

# 4) Copy the .bak out to Windows
docker cp "${CONTAINER}:$IN_CONTAINER" "$WIN_DIR/"

echo "✅ Backup saved to $WIN_DIR/$(basename "$IN_CONTAINER")"
