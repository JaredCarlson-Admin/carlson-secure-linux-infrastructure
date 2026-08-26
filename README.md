# Carlson Retail Group: Secure Two-Tier Linux Infrastructure

Built and documented by Jared Carlson.

## What this is

I built this as a hands-on project after passing my RHCSA and while studying for Security+. I wanted to practice on something closer to a real environment than a single lab VM, so I set up a fictional retail company's internal inventory system split across two RHEL servers: one runs the web app, the other holds the data.

## Architecture

```
                 [ Internal Network 10.0.0.0/24 ]

   servera (10.0.0.50)                serverb (10.0.0.60)
   -------------------                -------------------
   Apache (httpd, HTTPS only)         LVM storage volume
   SELinux enforcing                  NFS export
   firewalld (https only,     <---->  firewalld (nfs/rpc-bind/mountd)
   ssh restricted to subnet)          
   autofs mount to serverb
   serves /inventory/data over
   HTTPS via Apache alias
```

## What's actually running

- RHEL, two nodes: servera (application tier), serverb (storage tier)
- LVM on serverb for the inventory data volume
- NFS and autofs: serverb exports the storage, servera mounts it on demand
- Apache on servera, HTTPS only (mod_ssl, self-signed cert), HTTP disabled
- Apache serves the NFS-mounted data through an alias, not just a static local page
- SELinux enforcing. I hit a 403 the first time Apache tried to read the NFS content, and fixed it with the `httpd_use_nfs` boolean
- firewalld, HTTPS only externally, SSH restricted to the internal subnet
- Three bash scripts (health check, backup, log cleanup), each logging its own run, scheduled with a systemd timer instead of cron

## Why I built it this way

I wanted to go a bit past just following steps in a lab guide. Splitting storage from the app server, turning off root SSH login, and keeping SELinux on instead of disabling it are all things I know would matter in a real setup, so I made sure to actually do them here instead of taking shortcuts.

The SELinux piece is the part I understand best because I ran into a real problem with it. When I tried serving the NFS-mounted data over HTTPS, I got a 403 error. It turns out SELinux does not automatically trust content mounted over NFS the same way it trusts local files. Instead of just turning SELinux off to make the error go away, I looked into it and found the specific boolean (`httpd_use_nfs`) that was actually needed, and fixed it that way.

## Certifications this draws on

- **CompTIA A+**: provisioning the VMs, disk setup, basic hardware/OS troubleshooting
- **RHCSA**: user/group management, LVM, NFS, autofs, SELinux, systemd, firewalld
- **CompTIA Security+**: least privilege access, network segmentation, TLS, SSH hardening, log retention policy

## Proof of work

### 1. Base setup
`[SCREENSHOT: hostnamectl on both nodes]`

### 2. User & access management
`[SCREENSHOT: id carlson_admin + sshd_config PermitRootLogin]`

### 3. LVM storage
`[SCREENSHOT: sudo lvs + df -h /inventory_data]`

### 4. NFS export & autofs mount
`[SCREENSHOT: sudo exportfs -v + ls /inventory/data + matching file on both nodes]`

### 5. Web server running on HTTPS
`[SCREENSHOT: sudo systemctl status httpd + curl -kv https://localhost showing the TLS handshake]`

### 6. Apache reads NFS-mounted data — before the fix
`[SCREENSHOT: curl -k https://localhost/inventory/inventory_status.txt returning 403 Forbidden]`

### 7. SELinux enforcing, boolean fix, confirmed working
`[SCREENSHOT: getenforce + getsebool httpd_use_nfs + the same curl now returning the file]`

### 8. Firewall — least privilege, verified externally
`[SCREENSHOT: sudo firewall-cmd --list-all on servera + curl from serverb showing https succeeds and http fails]`

### 9. Automation scripts + scheduled timer
`[SCREENSHOT: script logs + systemctl list-timers]`

## Scripts

All three are in [`carlson_scripts/`](./carlson_scripts) in this repo:

- `system_check.sh`: pulls firewall state, httpd status, SELinux mode, and disk usage into one report
- `backup.sh`: compresses the web config/content nightly with a dated filename, logs success or failure
- `clean_logs.sh`: removes httpd logs older than 7 days, logs how many were removed

I scheduled it with a systemd timer (`carlson-backup.timer`) instead of a plain cron entry, since that is the newer approach RHCSA covers.
