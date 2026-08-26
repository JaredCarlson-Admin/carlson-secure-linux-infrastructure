#!/bin/bash
# Carlson Retail Group - nightly backup of web server config/content

BACKUP_DIR="/backup"
DATE=$(date +%F)
SRC="/var/www/html/"
DEST="$BACKUP_DIR/web_backup_$DATE.tar.gz"

sudo mkdir -p "$BACKUP_DIR"

if sudo tar -czf "$DEST" "$SRC"; then
  echo "$(date): backup succeeded -> $DEST" | sudo tee -a /var/log/carlson_scripts/backup.log
else
  echo "$(date): backup FAILED" | sudo tee -a /var/log/carlson_scripts/backup.log
  exit 1
fi
