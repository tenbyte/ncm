#!/bin/bash
# Version: 0.1.5

# Nextcloud config detection (erweitert)
NCM_LOCAL_CONF="$(dirname "$0")/../ncm_local.conf"
NEXTCLOUD_CONFIG=""
NEXTCLOUD_CONFIG_FOUND=0
NEXTCLOUD_PATH=""

# Erweiterte Pfad-Suche für Nextcloud
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
    
    # Teste Standard-Pfade
    for path in "${test_paths[@]}"; do
        if [ -f "$path" ]; then
            NEXTCLOUD_CONFIG="$path"
            NEXTCLOUD_PATH="$(dirname "$(dirname "$path")")"
            NEXTCLOUD_CONFIG_FOUND=1
            return 0
        fi
    done
    
    # Fallback: find-Befehl verwenden
    if command -v find >/dev/null 2>&1; then
        local find_result=$(find /var/www /opt /usr/share /home -name "config.php" -path "*/nextcloud/config/config.php" 2>/dev/null | head -1)
        if [ -n "$find_result" ] && [ -f "$find_result" ]; then
            NEXTCLOUD_CONFIG="$find_result"
            NEXTCLOUD_PATH="$(dirname "$(dirname "$find_result")")"
            NEXTCLOUD_CONFIG_FOUND=1
            return 0
        fi
    fi
    
    # Fallback: lokale Konfiguration prüfen
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

# Nextcloud-Konfiguration erkennen
detect_nextcloud_config

if [ "$NEXTCLOUD_CONFIG_FOUND" -eq 0 ]; then
    echo "❌ Nextcloud config.php not found! Please set the path in ncm_local.conf."
    exit 1
fi
sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:mode --on

echo ""
echo "Press Enter to return to main menu..."
read