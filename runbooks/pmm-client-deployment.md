# PMM Client Installation Guide

## Non-Root Deployment for Enterprise Database Monitoring

Production-ready installation guide for deploying Percona Monitoring and Management (PMM) Client using a non-root user in Oracle Linux / RHEL environments.

---

# Table of Contents

1. Overview
2. Deployment Model
3. Prerequisites
4. PMM Client Installation
5. PMM Agent Registration
6. Verification & Health Checks
7. PMM Client Management
8. Auto-Start Configuration
9. Troubleshooting
10. Uninstallation
11. Directory Structure
12. Quick Installation Script
13. Best Practices

---

# 1. Overview

## Purpose

This document provides a secure and lightweight deployment method for installing PMM Client without requiring root access.

The deployment is designed for:

* Enterprise database environments
* Restricted Linux servers
* Air-gapped or offline infrastructure
* Production observability platforms
* Standardized PMM onboarding workflows

---

## Key Features

* Non-root installation
* Offline-compatible deployment
* Portable tarball-based setup
* Minimal system dependency requirements
* User-level service management
* Production-ready monitoring registration

---

# 2. Deployment Model

```text
+------------------------------------------------+
|                 PMM SERVER                     |
|------------------------------------------------|
| Receives metrics and monitoring data           |
+------------------------------------------------+
                    ↑
                    │ HTTPS :443
                    │
+------------------------------------------------+
|                 DATABASE SERVER                |
|------------------------------------------------|
| PMM Client                                     |
| - pmm-agent                                    |
| - node_exporter                                |
| - vmagent                                      |
+------------------------------------------------+
```

---

# 3. Prerequisites

## Required Components

Before installation, ensure the following requirements are met.

| Requirement     | Details                       |
| --------------- | ----------------------------- |
| PMM Server      | Installed and accessible      |
| User Access     | Non-root Linux user           |
| Internet Access | Required for tarball download |
| Disk Space      | Minimum 200 MB                |
| Connectivity    | HTTPS access to PMM Server    |

---

## Supported Operating Systems

* Oracle Linux 8.x
* RHEL 8.x
* CentOS 8.x

---

# 4. PMM Client Installation

## Step 1 — Create Deployment Directory

Deployment path:

```text
/opt/pmm-client/
```

Create deployment directory:

```bash
sudo mkdir -p /opt/pmm-client
sudo chown -R $USER:$USER /opt/pmm-client
cd /opt/pmm-client
```

---

## Step 2 — Download PMM Client Tarball

```bash
wget https://downloads.percona.com/downloads/pmm3/3.4.1/binary/tarball/pmm-client-3.4.1-x86_64.tar.gz
```

---

## Step 3 — Extract Package

```bash
tar xfz pmm-client-3.4.1-x86_64.tar.gz
cd pmm-client-3.4.1
```

---

## Step 4 — Configure Installation Path

Define centralized installation location:

```bash
export PMM_DIR=/opt/pmm-client/current
```

layout:

```text
/opt/pmm-client/
├── current/
│   ├── bin/
│   ├── config/
│   ├── exporters/
│   ├── tools/
│   └── logs/
├── packages/
└── backups/
```

---

## Step 5 — Install PMM Client

```bash
./install_tarball
```

Expected output:

```text
Successfully installed PMM Client to /opt/pmm-client/current
```

---

## Step 6 — Configure Environment Variables

```bash
echo "export PMM_DIR=/opt/pmm-client/current" >> ~/.bashrc
```

```bash
echo 'export PATH=$PMM_DIR/bin:$PATH' >> ~/.bashrc
```

```bash
source ~/.bashrc
```

---

## Step 7 — Verify Installation

```bash
pmm-admin --version
```

```bash
pmm-agent --version
```

Expected version:

```text
3.4.1
```

---

# 5. PMM Agent Registration

## Step 1 — Register Node with PMM Server

Replace the following placeholders:

| Placeholder     | Description           |
| --------------- | --------------------- |
| `PMM_SERVER_IP` | PMM Server IP address |
| `YOUR_PASSWORD` | PMM admin password    |

---

## Registration Command

```bash
pmm-agent setup \
  --config-file=${PMM_DIR}/config/pmm-agent.yaml \
  --server-address=PMM_SERVER_IP:443 \
  --server-insecure-tls \
  --server-username=admin \
  --server-password='YOUR_PASSWORD' \
  --paths-tempdir=${PMM_DIR}/tmp \
  --paths-base=${PMM_DIR} \
  --force
```

Expected output:

```text
Registered.
Configuration file updated.
Please start pmm-agent...
```

---

## Step 2 — Start PMM Agent

```bash
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/pmm-agent.log 2>&1 &
```

```bash
sleep 3
```

---

## Step 3 — Verify Agent Status

```bash
pmm-admin status
```

```bash
pmm-admin list
```

Expected status:

```text
Connected: true
```

Expected agents:

```text
node_exporter: Running
vmagent: Running
```

---

# 6. Verification & Health Checks

## Validation Checklist

| Validation       | Command                    | Expected Result |
| ---------------- | -------------------------- | --------------- |
| Version Check    | `pmm-admin --version`      | Version 3.4.1   |
| PMM Connectivity | `pmm-admin status`         | Connected: true |
| Exporter Status  | `pmm-admin list`           | Running         |
| Agent Process    | `ps aux \| grep pmm-agent` | Process Active  |
| PMM UI           | Browser Access             | Node Visible    |

---

## Verify Running Process

```bash
ps aux | grep pmm-agent
```

---

## Verify PMM Server Connectivity

```bash
curl -k https://PMM_SERVER_IP:443/v1/version
```

---

# 7. PMM Client Management

## Status Commands

```bash
pmm-admin status
```

```bash
pmm-admin list
```

---

## View Logs

```bash
tail -f ${PMM_DIR}/pmm-agent.log
```

---

## Stop PMM Agent

```bash
pkill pmm-agent
```

---

## Start PMM Agent

```bash
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/pmm-agent.log 2>&1 &
```

---

## Restart PMM Agent

```bash
pkill pmm-agent
```

```bash
sleep 2
```

```bash
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/pmm-agent.log 2>&1 &
```

---

# 8. Auto-Start Configuration

## Configure User-Level systemd Service

Create service directory:

```bash
mkdir -p ~/.config/systemd/user
```

---

## Create PMM Agent Service

```bash
cat > ~/.config/systemd/user/pmm-agent.service <<EOF
[Unit]
Description=PMM Agent (User Service)
After=network.target

[Service]
Type=simple
ExecStart=$HOME/pmm/bin/pmm-agent --config-file=$HOME/pmm/config/pmm-agent.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
```

---

## Reload and Enable Service

```bash
systemctl --user daemon-reload
```

```bash
systemctl --user enable pmm-agent
```

```bash
systemctl --user start pmm-agent
```

```bash
systemctl --user status pmm-agent
```

---

# 9. Troubleshooting

## Issue — Node Already Exists

### Solution

Use the `--force` flag during setup.

```bash
--force
```

---

## Issue — Connection Refused

### Verify PMM Agent Process

```bash
ps aux | grep pmm-agent
```

### Restart Agent

```bash
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/pmm-agent.log 2>&1 &
```

---

## Issue — Command Not Found

### Reload Environment Variables

```bash
source ~/.bashrc
```

### Alternative Using Full Path

```bash
$HOME/pmm/bin/pmm-admin status
```

---

## Issue — Unable to Connect to PMM Server

### Test Connectivity

```bash
curl -k https://PMM_SERVER_IP:443/v1/version
```

### Verify Firewall Access

Ensure port `443/tcp` is reachable from the client server.

---

# 10. Uninstallation

## Stop PMM Agent

```bash
pkill pmm-agent
```

---

## Stop systemd Service (If Configured)

```bash
systemctl --user stop pmm-agent
```

```bash
systemctl --user disable pmm-agent
```

---

## Remove PMM Directories

```bash
rm -rf $HOME/pmm
```

```bash
rm -rf $HOME/pmm-client
```

---

## Remove Environment Variables

Edit bash profile:

```bash
nano ~/.bashrc
```

Remove:

```bash
export PMM_DIR=/opt/pmm-client/current
export PATH=$PMM_DIR/bin:$PATH
```

Reload profile:

```bash
source ~/.bashrc
```

---

# 11. Directory Structure

## Installation Layout

```text
/opt/pmm-client/
├── current/
│   ├── bin/              # PMM binaries
│   ├── config/           # PMM configuration files
│   ├── exporters/        # Monitoring exporters
│   ├── tools/            # PMM utilities
│   ├── tmp/              # Runtime temporary files
│   └── logs/             # PMM logs
├── packages/             # Downloaded installation packages
└── backups/              # Backup and rollback files
```

---

## Important Ports

| Port  | Service       |
| ----- | ------------- |
| 42000 | node_exporter |
| 42001 | vmagent       |
| 7777  | pmm-agent API |

---

## Environment Variables

```bash
export PMM_DIR=/opt/pmm-client/current
export PATH=$PMM_DIR/bin:$PATH
```

---

# 12. Quick Installation Script

## Automated Installation Script

```bash
#!/bin/bash

# PMM Client Installation Script

# Variables
PMM_SERVER_IP="127.0.0.1"
PMM_SERVER_PASSWORD="admin"
PMM_VERSION="3.4.1"

# Create directory
sudo mkdir -p /opt/pmm-client/packages && sudo chown -R $USER:$USER /opt/pmm-client
cd /opt/pmm-client/packages

# Download PMM Client
wget https://downloads.percona.com/downloads/pmm3/${PMM_VERSION}/binary/tarball/pmm-client-${PMM_VERSION}-x86_64.tar.gz

# Extract package
tar xfz pmm-client-${PMM_VERSION}-x86_64.tar.gz
cd pmm-client-${PMM_VERSION}

# Configure installation directory
export PMM_DIR=/opt/pmm-client/current

# Install PMM Client
./install_tarball

# Configure environment variables
echo "export PMM_DIR=/opt/pmm-client/current" >> ~/.bashrc
echo 'export PATH=$PMM_DIR/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Register PMM Agent
pmm-agent setup \
  --config-file=${PMM_DIR}/config/pmm-agent.yaml \
  --server-address=${PMM_SERVER_IP}:443 \
  --server-insecure-tls \
  --server-username=admin \
  --server-password="${PMM_SERVER_PASSWORD}" \
  --paths-tempdir=${PMM_DIR}/tmp \
  --paths-base=${PMM_DIR} \
  --force

# Start PMM Agent
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/pmm-agent.log 2>&1 &

sleep 3

# Verification
pmm-admin status
pmm-admin list
```

---

## Script Execution

Save file:

```bash
nano install-pmm-client.sh
```

Make executable:

```bash
chmod +x install-pmm-client.sh
```

Execute:

```bash
./install-pmm-client.sh
```

---

# 13. Best Practices

## Operational Recommendations

* Use dedicated monitoring users where possible.
* Restrict outbound network access to PMM Server only.
* Enable auto-start for persistent monitoring.
* Regularly review PMM agent logs.
* Validate exporter health after installation.

---

# Summary

This deployment method provides:

* Lightweight PMM onboarding
* Secure non-root deployment
* Portable offline installation
* Enterprise observability integration
* Standardized monitoring automation

The installation is suitable for production database environments and scalable infrastructure monitoring workflows.
