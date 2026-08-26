#!/bin/bash
# Carlson Retail Group - remove httpd logs older than 7 days

TARGET="/var/log/httpd/"
DAYS=7

COUNT=$(sudo find "$TARGET" -name "*.log" -mtime +$DAYS | wc -l)
sudo find "$TARGET" -name "*.log" -mtime +$DAYS -exec rm -f {} \;

echo "$(date): removed $COUNT log file(s) older than $DAYS days" | sudo tee -a /var/log/carlson_scripts/clean_logs.log
