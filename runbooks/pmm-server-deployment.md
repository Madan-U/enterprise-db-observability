# PMM Server Installation Guide

## Enterprise Database Observability Platform

Production-ready deployment guide for installing Percona Monitoring and Management (PMM) Server using Docker on Oracle Linux / RHEL 8.x environments.

---

# Table of Contents

1. Overview
2. Architecture
3. Prerequisites
4. Docker Installation
5. PMM Server Deployment
6. Firewall Configuration
7. Initial Access & Security Hardening
8. Verification & Health Checks
9. PMM Server Management
10. Troubleshooting
11. Best Practices
12. System Information Summary
13. References

---

# 1. Overview

## Purpose

This document provides a complete step-by-step installation procedure for deploying:

* Docker Engine
* Percona Monitoring and Management (PMM) Server
* Persistent PMM storage
* Production-ready monitoring services

The setup is designed for:

* Enterprise database monitoring
* Hybrid-cloud database environments
* Centralized observability platforms
* Production database infrastructure

---

## Environment Details

| Component        | Version                     |
| ---------------- | --------------------------- |
| Operating System | Oracle Linux Server 8.8     |
| Docker Version   | 27.3.1                      |
| PMM Version      | 3.4.1                       |
| Deployment Type  | Docker Container            |
| Architecture     | Dedicated Monitoring Server |

---

# 2. Architecture

## Deployment Model

```text
+------------------------------------------------+
|                 PMM SERVER                     |
|------------------------------------------------|
| Docker Container                               |
|                                                |
| - Grafana                                      |
| - VictoriaMetrics                              |
| - PostgreSQL                                   |
| - ClickHouse                                   |
| - PMM Managed                                  |
| - QAN API                                      |
+------------------------------------------------+
                ↑          ↑
                │ HTTPS    │
                │          │
+----------------+----------+----------------+
|                                           |
|           DATABASE SERVERS                |
|-------------------------------------------|
| MySQL / MariaDB / PostgreSQL / MongoDB    |
| PMM Client Installed                      |
+-------------------------------------------+
```

---

## Monitoring Flow

1. PMM Client collects metrics from database servers.
2. Metrics are securely transmitted to PMM Server over HTTPS.
3. PMM Server stores and visualizes monitoring data.
4. Grafana dashboards provide centralized observability.

---

# 3. Prerequisites

## System Requirements

| Requirement | Minimum                 | Recommended             |
| ----------- | ----------------------- | ----------------------- |
| CPU         | 2 Cores                 | 4+ Cores                |
| Memory      | 4 GB                    | 8+ GB                   |
| Storage     | 50 GB                   | 100+ GB                 |
| OS          | Oracle Linux / RHEL 8.x | Oracle Linux / RHEL 8.x |

---

## Required Access

* Root or sudo access
* Internet access for package downloads
* Firewall access for ports:

  * 80/tcp
  * 443/tcp

---

## Required Utilities

Verify wget is installed:

```bash
which wget
```

Install if missing:

```bash
sudo dnf install wget -y
```

---

# 4. Docker Installation

## Step 1 — Create Download Directory

```bash
mkdir -p /tmp/docker-rpms
cd /tmp/docker-rpms
```

---

## Step 2 — Download Required Docker RPM Packages

### Download containerd

```bash
wget https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/containerd.io-1.6.33-3.1.el8.x86_64.rpm
```

### Download docker-ce-cli

```bash
wget https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/docker-ce-cli-27.3.1-1.el8.x86_64.rpm
```

### Download docker-ce

```bash
wget https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/docker-ce-27.3.1-1.el8.x86_64.rpm
```

### Download docker-buildx-plugin

```bash
wget https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/docker-buildx-plugin-0.17.1-1.el8.x86_64.rpm
```

### Download docker-compose-plugin

```bash
wget https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/docker-compose-plugin-2.29.7-1.el8.x86_64.rpm
```

### Download libcgroup Dependency

```bash
wget https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/getPackage/libcgroup-0.41-19.el8.x86_64.rpm
```

---

## Step 3 — Verify Downloaded Files

```bash
ls -lh /tmp/docker-rpms/
```

Expected output:

```text
total 99M
-rw-r--r--. 1 root root  36M containerd.io-1.6.33-3.1.el8.x86_64.rpm
-rw-r--r--. 1 root root  14M docker-buildx-plugin-0.17.1-1.el8.x86_64.rpm
-rw-r--r--. 1 root root  28M docker-ce-27.3.1-1.el8.x86_64.rpm
-rw-r--r--. 1 root root 8.1M docker-ce-cli-27.3.1-1.el8.x86_64.rpm
-rw-r--r--. 1 root root  14M docker-compose-plugin-2.29.7-1.el8.x86_64.rpm
-rw-r--r--. 1 root root  70K libcgroup-0.41-19.el8.x86_64.rpm
```

---

## Step 4 — Install Docker Packages

```bash
cd /tmp/docker-rpms
```

Install RPMs in the following order:

```bash
rpm -ivh containerd.io-1.6.33-3.1.el8.x86_64.rpm
rpm -ivh docker-ce-cli-27.3.1-1.el8.x86_64.rpm
rpm -ivh docker-buildx-plugin-0.17.1-1.el8.x86_64.rpm
rpm -ivh docker-compose-plugin-2.29.7-1.el8.x86_64.rpm
rpm -ivh libcgroup-0.41-19.el8.x86_64.rpm
rpm -ivh docker-ce-27.3.1-1.el8.x86_64.rpm
```

> Note: RPM `NOKEY` warnings are expected in offline or unregistered environments.

---

## Step 5 — Start and Enable Docker Services

```bash
systemctl start docker
systemctl enable docker
systemctl enable containerd
```

Verify Docker service:

```bash
systemctl status docker
```

Verify Docker version:

```bash
docker --version
```

Expected output:

```text
Docker version 27.3.1, build ce12230
```

---

## Step 6 — Add User to Docker Group (Optional)

```bash
usermod -aG docker sysadmin
```

Verify group membership:

```bash
grep docker /etc/group
```

Expected output:

```text
docker:x:970:sysadmin
```

> User must log out and log back in for group changes to take effect.

---

# 5. PMM Server Deployment

## Step 1 — Download PMM Server Docker Image

```bash
cd /tmp/docker-rpms
```

```bash
wget https://downloads.percona.com/downloads/pmm3/3.4.1/docker/pmm-server-3.4.1.docker
```

Expected image size:

```text
Approximately 582 MB
```

---

## Step 2 — Verify Download

```bash
ls -lh pmm-server-3.4.1.docker
```

Expected output:

```text
-rw-r--r--. 1 root root 582M Oct 13 17:19 pmm-server-3.4.1.docker
```

---

## Step 3 — Load PMM Image into Docker

```bash
docker load < pmm-server-3.4.1.docker
```

Expected output:

```text
Loaded image: percona/pmm-server:3.4.1
```

---

## Step 4 — Verify Docker Image

```bash
docker images | grep pmm-server
```

Expected output:

```text
REPOSITORY           TAG       IMAGE ID       CREATED        SIZE
percona/pmm-server   3.4.1     648eb30efe08   4 weeks ago    2.74GB
```

---

## Step 5 — Create Persistent Docker Volume

```bash
docker volume create pmm-data
```

Verify volume:

```bash
docker volume ls | grep pmm-data
```

Expected output:

```text
local     pmm-data
```

---

## Step 6 — Deploy PMM Server Container

```bash
docker run -d \
  -p 80:8080 \
  -p 443:8443 \
  --name pmm-server \
  --restart always \
  -v pmm-data:/srv \
  percona/pmm-server:3.4.1
```

---

## Container Parameter Explanation

| Parameter           | Description                    |
| ------------------- | ------------------------------ |
| `-d`                | Run container in detached mode |
| `-p 80:8080`        | Map HTTP port                  |
| `-p 443:8443`       | Map HTTPS port                 |
| `--name pmm-server` | Container name                 |
| `--restart always`  | Auto restart after reboot      |
| `-v pmm-data:/srv`  | Persistent storage volume      |

---

## Step 7 — Verify PMM Container Status

```bash
docker ps
```

Detailed output:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Expected output:

```text
NAMES        STATUS                    PORTS
pmm-server   Up 23 seconds (healthy)   0.0.0.0:80->8080/tcp, 0.0.0.0:443->8443/tcp
```

---

## Step 8 — Monitor Initialization Logs

```bash
docker logs pmm-server
```

Real-time logs:

```bash
docker logs -f pmm-server
```

> Wait approximately 1–2 minutes for all services to initialize.

---

## Step 9 — Verify PMM Services

```bash
docker exec pmm-server supervisorctl status
```

Expected output:

```text
clickhouse                       RUNNING
grafana                          RUNNING
nginx                            RUNNING
pmm-agent                        RUNNING
pmm-managed                      RUNNING
postgresql                       RUNNING
qan-api2                         RUNNING
victoriametrics                  RUNNING
vmalert                          RUNNING
vmproxy                          RUNNING
```

---

# 6. Firewall Configuration

## Configure Required Firewall Rules

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

Verify firewall rules:

```bash
sudo firewall-cmd --list-ports
```

Expected output:

```text
80/tcp 443/tcp
```

---

# 7. Initial Access & Security Hardening

## Step 1 — Obtain Server IP Address

```bash
hostname -I
```

Alternative command:

```bash
ip addr show | grep inet
```

---

## Step 2 — Access PMM Web Interface

Open browser:

```text
http://<SERVER_IP>
```

Example:

```text
http://192.168.31.149
```

---

## Step 3 — Default Login Credentials

| Username | Password |
| -------- | -------- |
| admin    | admin    |

---

## Step 4 — Change Default Password (Mandatory)

### Method 1 — Command Line

```bash
docker exec -t pmm-server change-admin-password YourNewStrongPassword123!
```

---

### Method 2 — Web UI

1. Login using default credentials
2. Navigate to user profile
3. Select **Change Password**
4. Update password
5. Save changes

---

# 8. Verification & Health Checks

## PMM Dashboard Validation

Verify the following:

* PMM dashboard is accessible
* Grafana dashboards load successfully
* System metrics are visible
* PMM Server instance is monitored
* No service failures appear in logs

---

## Verify Container Health

```bash
docker ps
```

```bash
docker logs pmm-server
```

```bash
docker stats pmm-server --no-stream
```

```bash
docker exec pmm-server pmm-admin --version
```

---

## Test PMM API

HTTP:

```bash
curl http://localhost/v1/version
```

HTTPS:

```bash
curl -k https://localhost/v1/version
```

---

# 9. PMM Server Management

## Container Management Commands

### Start PMM Server

```bash
docker start pmm-server
```

### Stop PMM Server

```bash
docker stop pmm-server
```

### Restart PMM Server

```bash
docker restart pmm-server
```

### View Logs

```bash
docker logs pmm-server
```

### Follow Logs

```bash
docker logs -f pmm-server
```

### Access Container Shell

```bash
docker exec -it pmm-server bash
```

### Resource Usage

```bash
docker stats pmm-server
```

---

## PMM Service Management

### Check Service Status

```bash
docker exec pmm-server supervisorctl status
```

### Restart Service

```bash
docker exec pmm-server supervisorctl restart grafana
```

### Stop Service

```bash
docker exec pmm-server supervisorctl stop grafana
```

### Start Service

```bash
docker exec pmm-server supervisorctl start grafana
```

---

## Data Backup Procedure

### Verify Docker Volume

```bash
docker volume ls | grep pmm-data
```

### Inspect Volume

```bash
docker volume inspect pmm-data
```

### Backup PMM Data

```bash
docker stop pmm-server
```

```bash
tar -czf pmm-data-backup-$(date +%Y%m%d).tar.gz \
-C /var/lib/docker/volumes/pmm-data/_data .
```

```bash
docker start pmm-server
```

---

# 10. Troubleshooting

## Container Fails to Start

### Check Container Logs

```bash
docker logs pmm-server
```

### Check Port Conflicts

```bash
netstat -tuln | grep -E ':80|:443'
```

### Recreate Container

```bash
docker rm -f pmm-server
```

```bash
docker run -d \
-p 80:8080 \
-p 443:8443 \
--name pmm-server \
--restart always \
-v pmm-data:/srv \
percona/pmm-server:3.4.1
```

---

## Unable to Access Web Interface

### Verify Firewall

```bash
sudo firewall-cmd --list-ports
```

### Temporarily Disable Firewall

```bash
sudo systemctl stop firewalld
```

### Verify Container Status

```bash
docker ps | grep pmm-server
```

### Test Local Connectivity

```bash
curl http://localhost
```

---

## PMM Services Not Running

### Check Service Status

```bash
docker exec pmm-server supervisorctl status
```

### Restart Container

```bash
docker restart pmm-server
```

### Verify Resource Usage

```bash
docker stats pmm-server
```

---

## Docker Permission Denied Errors

### Verify Group Membership

```bash
groups
```

### Add User to Docker Group

```bash
sudo usermod -aG docker $USER
```

```bash
exit
```

> Re-login is required after updating group membership.

---

# 11. Best Practices

## Security Recommendations

* Change default credentials immediately.
* Restrict access to PMM ports.
* Use SSL certificates for production deployments.
* Regularly update Docker and PMM versions.
* Enable infrastructure backups.

---

## Operational Recommendations

* Monitor PMM resource consumption.
* Schedule periodic Docker volume backups.
* Keep PMM isolated on dedicated infrastructure.
* Use HTTPS for all PMM communication.
* Validate monitoring agent connectivity regularly.

---

# 12. System Information Summary

| Component           | Details                 |
| ------------------- | ----------------------- |
| Operating System    | Linux Server            |
| Docker Version      | 27.3.1                  |
| PMM Version         | 3.4.1                   |
| Container Name      | pmm-server              |
| Docker Volume       | pmm-data                |
| HTTP Port           | 80                      |
| HTTPS Port          | 443                     |
| Default Credentials | admin / admin           |

---

## PMM Services

| Service         | Purpose                     |
| --------------- | --------------------------- |
| PostgreSQL      | PMM internal database       |
| ClickHouse      | Query Analytics database    |
| Grafana         | Visualization dashboards    |
| Nginx           | Reverse proxy               |
| VictoriaMetrics | Time-series metrics storage |
| VMAlert         | Alert management            |
| VMProxy         | Metrics proxy               |
| pmm-agent       | Monitoring agent            |
| pmm-managed     | PMM management service      |
| qan-api2        | Query Analytics API         |

---

# Author Notes

This repository focuses on enterprise-grade database observability, monitoring automation, and operational reliability for modern database infrastructure.

The procedures documented here are designed for:

* Production environments
* Enterprise database operations teams
* Cloud and hybrid infrastructure
* Database reliability engineering workflows

