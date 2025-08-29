#!/bin/bash
# Version: 0.1.5 - SECURITY FIXED

NCM_LOCAL_CONF="$(dirname "$0")/../ncm_local.conf"
NEXTCLOUD_CONFIG=""
NEXTCLOUD_CONFIG_FOUND=0
NEXTCLOUD_PATH=""

detect_nextcloud_config() {
    local test_paths=(
        "/var/www/nextcloud/config/config.php"
        "/var/www/html/nextcloud/config/config.php"
        "/opt/nextcloud/config/config.php"
        "/usr/share/nextcloud/config/config.php"
        "/home/nextcloud/config/config.php"
        "./config/config.php"
        "../config/config.php"
        "../../config/config.php"
    )
    
    for path in "${test_paths[@]}"; do
        if [ -f "$path" ]; then
            NEXTCLOUD_CONFIG="$path"
            NEXTCLOUD_PATH="$(dirname "$(dirname "$path")")"
            NEXTCLOUD_CONFIG_FOUND=1
            return 0
        fi
    done
    
    if command -v find >/dev/null 2>&1; then
        local find_result=$(find /var/www /opt /usr/share /home -name "config.php" -path "*/nextcloud/config/config.php" 2>/dev/null | head -1)
        if [ -n "$find_result" ] && [ -f "$find_result" ]; then
            NEXTCLOUD_CONFIG="$find_result"
            NEXTCLOUD_PATH="$(dirname "$(dirname "$find_result")")"
            NEXTCLOUD_CONFIG_FOUND=1
            return 0
        fi
    fi
    
    if [ -f "$NCM_LOCAL_CONF" ]; then
        source "$NCM_LOCAL_CONF"
        if [ -n "$NEXTCLOUD_PATH" ] && [ -f "$NEXTCLOUD_PATH/config/config.php" ]; then
            NEXTCLOUD_CONFIG="$NEXTCLOUD_PATH/config/config.php"
            NEXTCLOUD_CONFIG_FOUND=1
            return 0
        fi
    fi
    
    return 1
}

detect_nextcloud_config

if [ "$NEXTCLOUD_CONFIG_FOUND" -eq 0 ]; then
    echo "❌ Nextcloud config.php not found! Please set the path in ncm_local.conf."
    exit 1
fi

get_nc_config_value() {
    local key="$1"
    if [ -f "$NEXTCLOUD_CONFIG" ]; then
        php -r "
        \$content = file_get_contents('$NEXTCLOUD_CONFIG');
        eval('?>' . \$content);
        if (isset(\$CONFIG['$key'])) {
            echo \$CONFIG['$key'];
        }
        " 2>/dev/null
    fi
}

# SICHERHEITSFUNKTION: Prüfe ob Pfad sicher ist
is_safe_log_path() {
    local path="$1"
    
    # Prüfe ob es eine gültige Datei ist (nicht ein Verzeichnis)
    if [ ! -f "$path" ]; then
        return 1
    fi
    
    # Prüfe ob der Dateiname "log" enthält oder typische Log-Endungen hat
    local filename=$(basename "$path")
    if [[ "$filename" == *"log"* ]] || [[ "$filename" == *.log ]] || [[ "$filename" == *.txt ]]; then
        return 0
    fi
    
    # Fallback: Prüfe ob es im bekannten Nextcloud-Struktur ist
    if [[ "$path" == */nextcloud.log ]] || [[ "$path" == */owncloud.log ]]; then
        return 0
    fi
    
    return 1
}

echo "🗑️ Nextcloud Log Cleaner (SECURE VERSION)"
echo "========================================="

NC_LOGFILE="$(get_nc_config_value logfile)"
NC_DATADIR="$(get_nc_config_value datadirectory)"

echo "🔍 Detected configuration:"
echo "   Logfile setting: ${NC_LOGFILE:-'not set'}"
echo "   Data directory: ${NC_DATADIR:-'not found'}"

# Sicherheitsprüfungen
LOGS_DELETED=0

if [ -n "$NC_LOGFILE" ]; then
    if is_safe_log_path "$NC_LOGFILE"; then
        echo "🗑️ Removing custom logfile: $NC_LOGFILE"
        rm -f "$NC_LOGFILE"
        LOGS_DELETED=1
        echo "✅ Custom logfile deleted: $NC_LOGFILE"
    else
        echo "⚠️ SECURITY: Skipping unsafe logfile path: $NC_LOGFILE"
        echo "   (Does not appear to be a log file)"
    fi
fi

# Standard Nextcloud Log im Datenverzeichnis
if [ -n "$NC_DATADIR" ] && [ -d "$NC_DATADIR" ]; then
    STANDARD_LOG="$NC_DATADIR/nextcloud.log"
    if [ -f "$STANDARD_LOG" ]; then
        echo "🗑️ Removing standard logfile: $STANDARD_LOG"
        rm -f "$STANDARD_LOG"
        LOGS_DELETED=1
        echo "✅ Standard logfile deleted: $STANDARD_LOG"
    fi
fi

if [ $LOGS_DELETED -eq 0 ]; then
    echo "ℹ️ No log files found to delete"
fi

echo ""
echo "Press Enter to return to main menu..."
read
