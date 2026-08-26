#!/bin/bash
# Carlson Retail Group - daily health and security check
# Run manually, or scheduled via systemd timer

LOG="/var/log/carlson_scripts/system_check.log"
sudo mkdir -p /var/log/carlson_scripts

{
  echo "=== System Check: $(date) ==="
  echo "Firewall state:"
  sudo firewall-cmd --state

  echo "Open services:"
  sudo firewall-cmd --list-services

  echo "httpd status:"
  systemctl is-active httpd

  echo "SELinux mode:"
  getenforce

  echo "Disk usage:"
  df -h /

  echo "-------------------------------------"
} | sudo tee -a "$LOG"
