#!/bin/bash
# Version: 0.1.5

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root!"
    exit 1
fi

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
NC_DATADIR="$(get_nc_config_value datadirectory)"

check_nextcloud() {
    if [ ! -d "$NEXTCLOUD_PATH" ]; then
        echo "❌ Nextcloud path not found! Please check ncm_local.conf."
        exit 1
    fi
}

run_occ() {
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" "$@"
}

echo "🔧 Nextcloud Database Maintenance"
echo "================================="

check_nextcloud

echo "🔄 Starting maintenance process..."

echo "⚡ Enabling maintenance mode..."
run_occ maintenance:mode --on

echo "📂 Fixing file permissions..."
chown -R www-data:www-data "$NEXTCLOUD_PATH"
echo "✅ Permissions updated"

echo "🔍 Adding missing database indices..."
run_occ db:add-missing-indices
echo "✅ Database indices updated"

echo "🛠️ Running repair process..."
run_occ maintenance:repair --include-expensive
echo "✅ Repair completed"

echo "⏰ Running cron job..."
sudo -u www-data php -f "$NEXTCLOUD_PATH/cron.php"
echo "✅ Cron job executed"

echo "⚡ Disabling maintenance mode..."
run_occ maintenance:mode --off

echo "✅ Maintenance completed successfully!"
echo "⚠️ If you encounter any issues, check the Nextcloud logs at:"
echo "🔹 $NEXTCLOUD_PATH/data/nextcloud.log"

echo -e "\nPress Enter to return to main menu..."
read