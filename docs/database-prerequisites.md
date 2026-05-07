Database Prerequisites & Integration
Before registering any database node with the PMM Client, the underlying database engine must be configured to expose its internal metrics, query logs, and performance schemas.

This document outlines the required user privileges and engine-level configurations for MongoDB, MySQL/MariaDB, and PostgreSQL.

🍃 1. MongoDB Requirements
To monitor MongoDB effectively, PMM requires a dedicated user with cluster monitoring privileges.

1.1 Create PMM Monitoring User
Connect to your MongoDB instance using mongosh as an administrator (e.g., admin DB) and execute the following:

use admin;

db.createUser({
  user: "pmm",
  pwd: "YOUR_SECURE_PASSWORD",
  roles: [
    { role: "clusterMonitor", db: "admin" },
    { role: "read", db: "local" }
  ]
});

🐬 2. MySQL / MariaDB Requirements
To utilize PMM's Query Analytics (QAN) for MySQL/MariaDB, both Slow Query Logging and the Performance Schema must be active and properly instrumented.

2.1 Configure Slow Query Logging (Runtime)
Apply these changes dynamically in the MySQL shell to enable logging without requiring an immediate database restart:

SET GLOBAL slow_query_log = 'ON';
SET GLOBAL log_output = 'FILE';
SET GLOBAL slow_query_log_file = '/var/log/mysql/mysql-slow.log';
SET GLOBAL long_query_time = 0.1;

2.2 Persist Configuration (my.cnf)
Ensure the settings persist across server reboots by adding them to your my.cnf (or my.cnf.d/server.cnf):

[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 0.1
log_output = FILE
performance_schema = ON

Note: If performance_schema was previously set to OFF, a database service restart is required to activate it.

2.3 Enable Performance Schema Consumers
Run the following inside the MySQL shell to enable granular query instrumentation. This allows PMM to capture wait events and statement metrics:

UPDATE performance_schema.setup_consumers 
SET ENABLED = 'YES' 
WHERE NAME LIKE '%statement%';

UPDATE performance_schema.setup_instruments 
SET ENABLED = 'YES', TIMED = 'YES' 
WHERE NAME LIKE 'statement/%';

UPDATE performance_schema.setup_consumers 
SET ENABLED = 'YES' 
WHERE NAME LIKE '%wait%';

2.4 Create PMM Monitoring User
Create the user and grant the necessary privileges to read the performance schema and global states:

CREATE USER 'pmm'@'127.0.0.1' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';

GRANT SELECT, PROCESS, REPLICATION CLIENT, SHOW DATABASES ON *.* TO 'pmm'@'127.0.0.1';
GRANT SELECT ON performance_schema.* TO 'pmm'@'127.0.0.1';

FLUSH PRIVILEGES;

🐘 3. PostgreSQL Requirements
For PostgreSQL environments (e.g., UAT/Prod), PMM requires the pg_stat_statements extension to capture query analytics.

3.1 Pre-Configuration (postgresql.conf)
Ensure your postgresql.conf has the following parameters set.

Note: Modifying shared_preload_libraries requires a database service restart.

shared_preload_libraries = 'pg_stat_statements'
track_activity_query_size = 2048
pg_stat_statements.track = all

3.2 Create PMM Monitoring User
Connect to your PostgreSQL database (psql) as a superuser (e.g., postgres) and execute:

-- Create the monitoring role
CREATE ROLE pmm WITH LOGIN PASSWORD 'YOUR_SECURE_PASSWORD';

-- Grant native monitoring privileges (PostgreSQL 10+)
GRANT pg_monitor TO pmm;

-- Enable the extension in the target database
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
