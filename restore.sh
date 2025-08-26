#!/usr/bin/env bash
set -euo pipefail

# --- Parameters ---
CONTAINER="${1:-sql2}"         # container name
DBNAME="${2:-YourDbName}"      # target database name
BAKFILE="${3:-/mnt/c/sqlbackups/YourDbName.bak}"  # path to .bak file on Windows (via /mnt/c)

# --- Derived ---
BASENAME=$(basename "$BAKFILE")
IN_CONTAINER="/var/opt/mssql/backups/$BASENAME"

echo "▶ Restoring database '$DBNAME' from backup '$BAKFILE' into container '$CONTAINER'"

# Copy .bak into container
docker cp "$BAKFILE" "$CONTAINER:$IN_CONTAINER"

# Discover logical file names in the .bak
echo "▶ Discovering logical file names..."
docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'MyPassw0rd!' -C \
  -Q "RESTORE FILELISTONLY FROM DISK = N'$IN_CONTAINER'" -W -s"," > filelist.csv

LOGICAL_DATA=$(awk -F',' 'NR==3 {print $1}' filelist.csv | xargs)
LOGICAL_LOG=$(awk -F',' 'NR==4 {print $1}' filelist.csv | xargs)

echo "▶ Logical data file: $LOGICAL_DATA"
echo "▶ Logical log  file: $LOGICAL_LOG"

# Run restore
echo "▶ Running RESTORE DATABASE..."
docker exec -i "$CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'MyPassw0rd!' -C \
  -Q "RESTORE DATABASE [$DBNAME]
      FROM DISK = N'$IN_CONTAINER'
      WITH MOVE '$LOGICAL_DATA' TO '/var/opt/mssql/data/${DBNAME}.mdf',
           MOVE '$LOGICAL_LOG'  TO '/var/opt/mssql/data/${DBNAME}_log.ldf',
           REPLACE"

echo "✅ Database '$DBNAME' restored successfully!"
