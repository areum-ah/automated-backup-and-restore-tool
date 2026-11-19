#!/bin/bash

# ==========================================
# AUTOMATED BACKUP AND RESTORE TOOL
# ==========================================

# Get the location of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define backup and log directories
BACKUP_DIR="$SCRIPT_DIR/backups"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/backup_log.txt"

# Create required folders
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"


# ==========================================
# 1. CREATE BACKUP
# ==========================================

create_backup() {

    echo "Enter full path of directory to backup:"
    read -r SRC_DIR

    if [ ! -d "$SRC_DIR" ]; then
        echo "Error: Directory not found!" | tee -a "$LOG_FILE"
        return
    fi

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"

    echo "Creating backup..."

    SRC_PARENT=$(dirname "$SRC_DIR")
    SRC_NAME=$(basename "$SRC_DIR")

    if tar -czf "$BACKUP_FILE" -C "$SRC_PARENT" "$SRC_NAME" 2>>"$LOG_FILE"; then
        echo "Backup created: $BACKUP_FILE" | tee -a "$LOG_FILE"
        echo "$(date): Backup of $SRC_DIR successful." >> "$LOG_FILE"
    else
        echo "Backup failed!" | tee -a "$LOG_FILE"
    fi
}


# ==========================================
# 2. RESTORE BACKUP
# ==========================================

restore_backup() {

    echo "Available backups:"
    ls "$BACKUP_DIR"

    echo "Enter name of backup file to restore:"
    read -r BACKUP_NAME

    echo "Enter destination directory to restore into:"
    read -r RESTORE_PATH

    if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
        echo "Error: Backup file not found!" | tee -a "$LOG_FILE"
        return
    fi

    mkdir -p "$RESTORE_PATH"

    if tar -xzf "$BACKUP_DIR/$BACKUP_NAME" -C "$RESTORE_PATH"; then
        echo "Successfully restored to $RESTORE_PATH" | tee -a "$LOG_FILE"
        echo "$(date): Restored $BACKUP_NAME to $RESTORE_PATH" >> "$LOG_FILE"
    else
        echo "Restore failed!" | tee -a "$LOG_FILE"
    fi
}


# ==========================================
# 3. SCHEDULE AUTOMATIC BACKUP
# ==========================================

schedule_backup() {

    echo "Enter directory to backup automatically:"
    read -r DIR

    if [ ! -d "$DIR" ]; then
        echo "Error: Directory not found!"
        return
    fi

    echo "Enter frequency (in minutes, 1-59):"
    read -r MINUTES

    if ! [[ "$MINUTES" =~ ^[0-9]+$ ]] || [ "$MINUTES" -lt 1 ] || [ "$MINUTES" -gt 59 ]; then
        echo "Invalid frequency!"
        return
    fi

    SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"

    CRON_JOB="*/$MINUTES * * * * /bin/bash \"$SCRIPT_PATH\" auto \"$DIR\""

    (crontab -l 2>/dev/null | grep -vF "$SCRIPT_PATH auto"; echo "$CRON_JOB") | crontab -

    echo "Scheduled backup every $MINUTES minutes for $DIR" | tee -a "$LOG_FILE"
}


# ==========================================
# 4. AUTOMATIC BACKUP (CRON)
# ==========================================

auto_backup() {

    SRC_DIR="$1"

    if [ ! -d "$SRC_DIR" ]; then
        echo "$(date): Auto backup failed. Directory not found: $SRC_DIR" >> "$LOG_FILE"
        return 1
    fi

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_FILE="$BACKUP_DIR/auto_backup_${TIMESTAMP}.tar.gz"

    SRC_PARENT=$(dirname "$SRC_DIR")
    SRC_NAME=$(basename "$SRC_DIR")

    if tar -czf "$BACKUP_FILE" -C "$SRC_PARENT" "$SRC_NAME" >> "$LOG_FILE" 2>&1; then
        echo "$(date): Auto backup completed for $SRC_DIR" >> "$LOG_FILE"
    else
        echo "$(date): Auto backup failed for $SRC_DIR" >> "$LOG_FILE"
    fi
}


# ==========================================
# 5. EMAIL SUMMARY LOG
# ==========================================

send_email_summary() {

    echo "Enter your email address:"
    read -r EMAIL

    if [ ! -s "$LOG_FILE" ]; then
        echo "Log file is empty, nothing to send."
        return
    fi

    if command -v mail >/dev/null 2>&1; then
        mail -s "Backup Summary Log" "$EMAIL" < "$LOG_FILE"
        echo "Email command executed."
        echo "$(date): Email summary requested for $EMAIL" >> "$LOG_FILE"
    else
        echo "Mail utility is not installed on this Mac."
        echo "Email feature is unavailable."
    fi
}


# ==========================================
# 6. SEARCH LOGS (GREP)
# ==========================================

search_logs() {

    echo "Enter keyword or date to search in logs:"
    read -r KEYWORD

    echo "Matching entries:"

    grep -i "$KEYWORD" "$LOG_FILE" || echo "No matches found."
}


# ==========================================
# 7. SHOW LOG SUMMARY (AWK)
# ==========================================

log_summary() {

    echo "Backup Summary:"

    awk '
    /Backup of/ {b++}
    /Restored/ {r++}
    END {
        print "--------------------------"
        print "Total Backups : " (b+0)
        print "Total Restores: " (r+0)
        print "--------------------------"
    }' "$LOG_FILE"
}


# ==========================================
# 8. CLEAN LOG FILE (SED)
# ==========================================

clean_logs() {

    echo "Cleaning log file..."

    sed -i '' '/^$/d' "$LOG_FILE"

    echo "Log file cleaned."
}


# ==========================================
# AUTOMATIC MODE FOR CRON
# ==========================================

if [ "$1" = "auto" ]; then
    auto_backup "$2"
    exit $?
fi


# ==========================================
# MAIN MENU
# ==========================================

while true; do

    echo ""
    echo "======================================"
    echo "     AUTOMATED BACKUP & RESTORE TOOL"
    echo "======================================"
    echo "1. Create Backup"
    echo "2. Restore Backup"
    echo "3. Schedule Automatic Backup"
    echo "4. View Backup Log"
    echo "5. Email Summary Log"
    echo "6. Search Logs (grep)"
    echo "7. Show Log Summary (awk)"
    echo "8. Clean Log File (sed)"
    echo "9. Exit"
    echo "======================================"

    echo -n "Enter your choice: "
    read -r choice

    case "$choice" in

        1) create_backup ;;
        2) restore_backup ;;
        3) schedule_backup ;;
        4) cat "$LOG_FILE" ;;
        5) send_email_summary ;;
        6) search_logs ;;
        7) log_summary ;;
        8) clean_logs ;;
        9) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option!" ;;

    esac

done
