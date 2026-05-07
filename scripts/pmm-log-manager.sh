#!/bin/bash

# ============================================================================
# SCRIPT NAME: pmm_log_manager.sh
# PURPOSE:
#   Enterprise-grade PMM log rotation and retention management
#
# DESCRIPTION:
#   - Compresses PMM agent logs when threshold is exceeded
#   - Safely truncates active log without interrupting PMM services
#   - Maintains compressed backup retention
#   - Prevents filesystem exhaustion in production environments
#
# STANDARD DIRECTORY LAYOUT:
#   /opt/pmm-client/
#   ├── current/
#   │   ├── config/
#   │   ├── logs/
#   │   ├── scripts/
#   │   └── tmp/
#   └── backups/
#       └── logs/
#
# AUTHOR: Enterprise DB Observability
# ============================================================================

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

LOG_FILE="/opt/pmm-client/current/logs/pmm-agent.log"
BACKUP_DIR="/opt/pmm-client/backups/logs"

MAX_SIZE_MB=500
RETENTION_DAYS=7

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ----------------------------------------------------------------------------
# Directory Validation
# ----------------------------------------------------------------------------

mkdir -p "$BACKUP_DIR"

# ----------------------------------------------------------------------------
# Log File Validation
# ----------------------------------------------------------------------------

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: PMM log file not found: $LOG_FILE"
    exit 1
fi

# ----------------------------------------------------------------------------
# Current Log Size Check
# ----------------------------------------------------------------------------

FILE_SIZE_MB=$(du -m "$LOG_FILE" | awk '{print $1}')

if [ "$FILE_SIZE_MB" -gt "$MAX_SIZE_MB" ]; then

    echo "=========================================================="
    echo "PMM Log Rotation Started"
    echo "Timestamp       : $(date)"
    echo "Current Size    : ${FILE_SIZE_MB} MB"
    echo "Threshold Limit : ${MAX_SIZE_MB} MB"
    echo "=========================================================="

    BACKUP_FILE="${BACKUP_DIR}/pmm-agent_${TIMESTAMP}.log.gz"

    # ------------------------------------------------------------------------
    # Compress Existing Log
    # ------------------------------------------------------------------------

    if gzip -c "$LOG_FILE" > "$BACKUP_FILE"; then

        echo "Compressed backup created:"
        echo "$BACKUP_FILE"

        # --------------------------------------------------------------------
        # Safe Log Truncation
        # --------------------------------------------------------------------

        truncate -s 0 "$LOG_FILE"

        echo "Active PMM log truncated successfully."

    else

        echo "ERROR: Failed to create compressed backup."
        echo "Log truncation aborted to prevent data loss."

        exit 1

    fi

    # ------------------------------------------------------------------------
    # Retention Cleanup
    # ------------------------------------------------------------------------

    find "$BACKUP_DIR" \
        -type f \
        -name "pmm-agent_*.log.gz" \
        -mtime +$RETENTION_DAYS \
        -delete

    echo "Retention cleanup completed."
    echo "Deleted archives older than ${RETENTION_DAYS} days."

    echo "=========================================================="
    echo "PMM Log Rotation Completed Successfully"
    echo "=========================================================="

else

    echo "$(date): PMM log size (${FILE_SIZE_MB} MB) within threshold."

fi
