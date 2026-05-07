# Database Prerequisites & Integration

Before registering any database node with the PMM Client, the underlying database engine must be configured to expose internal metrics, query logs, and performance schemas.

This document outlines the required database configurations, monitoring privileges, and engine-level integrations for:

- MongoDB
- MySQL / MariaDB
- PostgreSQL

---

# 🍃 1. MongoDB Requirements

To monitor MongoDB effectively, PMM requires a dedicated monitoring user with cluster-level monitoring privileges.

## 1.1 Create PMM Monitoring User

Connect to the MongoDB instance using `mongosh` as an administrative user and execute the following:

```javascript
use admin;

db.createUser({
  user: "pmm",
  pwd: "YOUR_SECURE_PASSWORD",
  roles: [
    { role: "clusterMonitor", db: "admin" },
    { role: "read", db: "local" }
  ]
});
```

### Required MongoDB Roles

| Role | Database | Purpose |
| :--- | :--- | :--- |
| `clusterMonitor` | `admin` | Enables cluster and server metric collection |
| `read` | `local` | Allows access to replication and oplog metadata |

---

# 🐬 2. MySQL / MariaDB Requirements

To enable PMM Query Analytics (QAN) for MySQL/MariaDB environments, both:

- Slow Query Logging
- Performance Schema

must be enabled and properly instrumented.

---

## 2.1 Configure Slow Query Logging (Runtime)

Apply the following configuration dynamically from the MySQL shell:

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL log_output = 'FILE';
SET GLOBAL slow_query_log_file = '/var/log/mysql/mysql-slow.log';
SET GLOBAL long_query_time = 0.1;
```

### Parameter Explanation

| Parameter | Description |
| :--- | :--- |
| `slow_query_log` | Enables slow query logging |
| `log_output` | Writes logs to file output |
| `slow_query_log_file` | Defines slow query log file path |
| `long_query_time` | Captures queries exceeding 100ms |

---

## 2.2 Persist Configuration (`my.cnf`)

To ensure settings persist across database restarts, add the following under the `[mysqld]` section:

```ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 0.1
log_output = FILE
performance_schema = ON
```

### Common Configuration Locations

| Distribution | Configuration File |
| :--- | :--- |
| RHEL / Oracle Linux | `/etc/my.cnf` |
| Ubuntu / Debian | `/etc/mysql/my.cnf` |
| MariaDB | `/etc/my.cnf.d/server.cnf` |

> **Important:**  
> If `performance_schema` was previously disabled, a database service restart is required.

---

## 2.3 Enable Performance Schema Consumers

Execute the following statements to enable statement instrumentation and wait-event collection:

```sql
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME LIKE '%statement%';

UPDATE performance_schema.setup_instruments
SET ENABLED = 'YES', TIMED = 'YES'
WHERE NAME LIKE 'statement/%';

UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME LIKE '%wait%';
```

### Why This Is Required

These configurations allow PMM to collect:

- Query execution metrics
- Wait events
- Statement latency
- Performance bottlenecks
- Query analytics data

---

## 2.4 Create PMM Monitoring User

Create a dedicated monitoring user and grant the required privileges:

```sql
CREATE USER 'pmm'@'127.0.0.1'
IDENTIFIED BY 'YOUR_SECURE_PASSWORD';

GRANT SELECT, PROCESS, REPLICATION CLIENT, SHOW DATABASES
ON *.* TO 'pmm'@'127.0.0.1';

GRANT SELECT
ON performance_schema.*
TO 'pmm'@'127.0.0.1';

FLUSH PRIVILEGES;
```

### Required MySQL Privileges

| Privilege | Purpose |
| :--- | :--- |
| `SELECT` | Read performance and metadata tables |
| `PROCESS` | Inspect running sessions |
| `REPLICATION CLIENT` | Access replication state and binary log info |
| `SHOW DATABASES` | Enumerate database inventory |

---

# 🐘 3. PostgreSQL Requirements

For PostgreSQL environments, PMM requires the `pg_stat_statements` extension to collect query execution statistics and workload analytics.

---

## 3.1 PostgreSQL Configuration (`postgresql.conf`)

Update the following parameters inside `postgresql.conf`:

```ini
shared_preload_libraries = 'pg_stat_statements'
track_activity_query_size = 2048
pg_stat_statements.track = all
```

### Parameter Explanation

| Parameter | Purpose |
| :--- | :--- |
| `shared_preload_libraries` | Loads the `pg_stat_statements` extension |
| `track_activity_query_size` | Increases query text capture size |
| `pg_stat_statements.track` | Tracks all SQL statements |

> **Important:**  
> Changes to `shared_preload_libraries` require a PostgreSQL service restart.

---

## 3.2 Create PMM Monitoring User

Connect using `psql` as a PostgreSQL superuser and execute:

```sql
-- Create monitoring role
CREATE ROLE pmm
WITH LOGIN PASSWORD 'YOUR_SECURE_PASSWORD';

-- Grant monitoring privileges
GRANT pg_monitor TO pmm;

-- Enable query statistics extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

### PostgreSQL Monitoring Components

| Component | Purpose |
| :--- | :--- |
| `pg_monitor` | Grants native monitoring visibility |
| `pg_stat_statements` | Captures SQL execution statistics |
| `track_activity_query_size` | Improves query visibility for long SQL text |

---

# ✅ Validation Checklist

Before registering the database node with PMM, validate the following requirements:

| Database Engine | Validation Item |
| :--- | :--- |
| MongoDB | PMM monitoring user created |
| MongoDB | `clusterMonitor` role assigned |
| MySQL/MariaDB | Slow Query Log enabled |
| MySQL/MariaDB | Performance Schema enabled |
| PostgreSQL | `pg_stat_statements` extension enabled |
| PostgreSQL | `shared_preload_libraries` configured |
| All Engines | Monitoring user credentials validated |

---

# 📌 Recommended Best Practices

- Use strong passwords for monitoring accounts
- Restrict PMM users to trusted hosts or subnets
- Rotate monitoring credentials periodically
- Monitor slow query log disk utilization
- Validate database connectivity before PMM registration
- Test monitoring users independently before onboarding

---
