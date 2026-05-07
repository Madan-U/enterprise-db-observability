# Database Service Registration Guide

## PMM Database Monitoring Configuration

Enterprise-grade procedures for onboarding database services into Percona Monitoring and Management (PMM).

This guide covers:

* MySQL Monitoring
* MariaDB Monitoring
* MongoDB Monitoring
* PostgreSQL Monitoring

---

# Table of Contents

1. Overview
2. Monitoring Architecture
3. MySQL / MariaDB Monitoring
4. MongoDB Monitoring
5. PostgreSQL Monitoring
6. Verification Procedures
7. Operational Best Practices
8. Troubleshooting

---

# 1. Overview

## Purpose

This document standardizes the onboarding process for registering database services with PMM Client.

The procedures are designed for:

* Enterprise observability platforms
* Production database environments
* Hybrid-cloud infrastructure
* Database Reliability Engineering (DBRE)
* Operational monitoring standardization

---

## Monitoring Components

| Component  | Purpose                                    |
| ---------- | ------------------------------------------ |
| PMM Server | Centralized monitoring platform            |
| PMM Client | Monitoring agent installed on DB server    |
| Exporters  | Database metrics collection                |
| QAN        | Query Analytics and performance monitoring |

---

# 2. Monitoring Architecture

```text
+------------------------------------------------+
|                 PMM SERVER                     |
|------------------------------------------------|
| Grafana | VictoriaMetrics | QAN | Alerting     |
+------------------------------------------------+
                     ↑
                     │ HTTPS
                     │
+------------------------------------------------+
|               DATABASE SERVER                  |
|------------------------------------------------|
| PMM Client                                     |
| - mysql_exporter                               |
| - mongodb_exporter                             |
| - postgres_exporter                            |
| - node_exporter                                |
+------------------------------------------------+
```

---

# 3. MySQL / MariaDB Monitoring

## Overview

PMM monitoring for MySQL and MariaDB includes:

* System metrics
* Database metrics
* Query Analytics (QAN)
* Slow query monitoring
* Performance Schema metrics
* Replication monitoring

---

# 3.1 Configure Slow Query Logging

## Runtime Configuration

Execute inside MySQL or MariaDB shell:

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL log_output = 'FILE';
SET GLOBAL slow_query_log_file = '/<your path>/mariadb-slow.log';
SET GLOBAL long_query_time = 0;
```

---

## Persistent Configuration

Update `my.cnf`:

```ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /<your path>/mariadb-slow.log
long_query_time = 0.1
log_output = FILE
performance_schema = ON
```

---

## Restart Database Service

Restart database service after configuration updates.

Example:

```bash
systemctl restart mariadb
```

or

```bash
systemctl restart mysqld
```

---

# 3.2 Create PMM Monitoring User

## Create Dedicated Monitoring Account

```sql
CREATE USER 'pmm'@'localhost' IDENTIFIED BY 'StrongPassword';
```

Grant monitoring privileges:

```sql
GRANT SELECT, PROCESS, REPLICATION CLIENT, SHOW DATABASES ON *.* TO 'pmm'@'localhost';
```

```sql
GRANT SELECT ON performance_schema.* TO 'pmm'@'localhost';
```

```sql
FLUSH PRIVILEGES;
```

---

# 3.3 Verify Performance Schema

## Check Performance Schema Status

```sql
SHOW VARIABLES LIKE 'performance_schema';
```

Expected value:

```text
ON
```

---

## Enable Performance Schema Consumers

```sql
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME LIKE '%statement%';
```

```sql
UPDATE performance_schema.setup_instruments
SET ENABLED = 'YES', TIMED = 'YES'
WHERE NAME LIKE 'statement/%';
```

```sql
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME LIKE '%wait%';
```

---

# 3.4 Register MySQL / MariaDB Service in PMM

## TCP-Based Registration

```bash
pmm-admin add mysql \
  --username=pmm \
  --password=StrongPassword \
  --host=127.0.0.1 \
  --port=3306 \
  --query-source=slowlog \
  --slow-log-path=/<your path>/mariadb-slow.log \
  --service-name=cluster-name \
  --service-name=mariadb-uat
```

---

## Socket-Based Registration

```bash
pmm-admin add mysql \
  --username=pmm \
  --password=StrongPassword \
  --socket=/var/lib/mysql/mysql.sock \
  --environment=prod \
  --query-source=perfschema \
  --service-name=cluster-name \
  --service-name=mariadb-uat
```
  
---

# 4. MongoDB Monitoring

## Overview

MongoDB monitoring provides:

* Cluster metrics
* Replication monitoring
* WiredTiger metrics
* Query Analytics
* Profiling metrics
* Resource utilization insights

---

# 4.1 Create MongoDB Monitoring User

Login using `mongosh`:

```javascript
use admin

db.createUser({
  user: "user",
  pwd: "password",
  roles: [
    { role: "clusterMonitor", db: "readAnyDatabase" },
    { role: "read", db: "local" }
  ]
})
```

---

# 4.2 Register MongoDB Services

## Enable MongoDB Profiling

```sql
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: 100
```

## Standard MongoDB Deployment

```bash
pmm-admin add mongodb \
  --username=dbuser \
  --password='password' \
  --host=127.0.0.1 \
  --port=27017 \
  --service-name=<your service name> \
  --cluster=<your cluster name> \
  --environment=production \
  --enable-all-collectors
```

---

# 5. PostgreSQL Monitoring

## Overview

PostgreSQL monitoring includes:

* Query performance monitoring
* pg_stat_statements analytics
* Replication metrics
* Session monitoring
* WAL metrics
* Vacuum and checkpoint visibility

---

# 5.1 Enable Required Extensions

## Enable pg_stat_statements

Edit `postgresql.conf`:

```ini
shared_preload_libraries = 'pg_stat_statements'
track_activity_query_size = 2048
pg_stat_statements.track = all
```

---

## Enable Logging Collector

```ini
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_min_duration_statement = 1000
```

---

## Restart PostgreSQL Service

```bash
systemctl restart postgresql
```

---

# 5.2 Create PMM Monitoring User

Login as PostgreSQL superuser:

```sql
CREATE USER pmm WITH PASSWORD 'StrongPassword';
```

Grant monitoring permissions:

```sql
GRANT pg_monitor TO pmm;
```

Enable extension:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

# 5.3 Register PostgreSQL Service in PMM

## Standard PostgreSQL Registration

```bash
pmm-admin add postgresql \
  --username=pmm \
  --password='StrongPassword' \
  --host=127.0.0.1 \
  --port=5432 \
  --query-source=pgstatmonitor \
  --service-name=<your server name>
```
---

## Recommended Query Sources

| Query Source       | Recommended Usage                          |
| ------------------ | ------------------------------------------ |
| `pgstatmonitor`    | Preferred for modern PostgreSQL monitoring |
| `pgstatstatements` | Standard PostgreSQL query analytics        |

---

# 6. Verification Procedures

## Verify Registered Services

```bash
pmm-admin list
```

---

## Verify PMM Agent Status

```bash
pmm-admin status
```

Expected output:

```text
Connected: true
```

---

## Verify Exporters

```bash
ps aux | grep exporter
```

---

## Verify Service Visibility in PMM UI

Check the following sections:

* Inventory
* Nodes
* Services
* QAN Dashboard
* Home Dashboard

---

# 7. Operational Best Practices

## Security Recommendations

* Use dedicated monitoring accounts
* Avoid using administrative database users
* Rotate monitoring passwords periodically
* Restrict PMM access to internal networks
* Enable TLS where possible

---

## Monitoring Recommendations

* Enable slow query logging
* Monitor replication lag
* Review QAN dashboards regularly
* Configure alerting thresholds
* Standardize exporter deployment

---

# 8. Troubleshooting

## Service Not Appearing in PMM

Verify registration:

```bash
pmm-admin list
```

Restart PMM agent:

```bash
pkill pmm-agent
```

```bash
nohup pmm-agent \
--config-file=${PMM_DIR}/config/pmm-agent.yaml \
> ${PMM_DIR}/logs/pmm-agent.log 2>&1 &
```

---

## Query Analytics Not Working

### MySQL / MariaDB

Verify:

* Slow query logging enabled
* Performance schema enabled
* Slow log path accessible

---

### MongoDB

Verify profiler configuration:

```javascript
db.getProfilingStatus()
```

---

### PostgreSQL

Verify extension:

```sql
SELECT * FROM pg_extension WHERE extname='pg_stat_statements';
```

---

## Connectivity Issues

Test PMM server access:

```bash
curl -k https://PMM_SERVER_IP:443/v1/version
```

Verify firewall connectivity:

```bash
telnet PMM_SERVER_IP 443
```

---

# Summary

This guide provides standardized onboarding procedures for integrating:

* MySQL
* MariaDB
* MongoDB
* PostgreSQL

into enterprise PMM monitoring infrastructure.

The procedures are aligned with:

* Production monitoring standards
* Enterprise observability practices
* DBRE operational workflows
* Infrastructure monitoring automation
