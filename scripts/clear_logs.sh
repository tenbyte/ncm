#!/bin/bash
# Version: 0.1.5

NCM_LOCAL_CONF="$(dirname "$0")/../ncm_local.conf"
NEXTCLOUD_CONFIG=""
NEXTCLOUD_CONFIG_FOUND=0
NEXTCLOUD_PATH=""
if [ -f "/var/www/nextcloud/config/config.php" ]; then
    NEXTCLOUD_CONFIG="/var/www/nextcloud/config/config.php"
    NEXTCLOUD_PATH="/var/www/nextcloud"
    NEXTCLOUD_CONFIG_FOUND=1
elif [ -f "/var/www/html/nextcloud/config/config.php" ]; then
    NEXTCLOUD_CONFIG="/var/www/html/nextcloud/config/config.php"
    NEXTCLOUD_PATH="/var/www/html/nextcloud"
    NEXTCLOUD_CONFIG_FOUND=1
elif [ -f "$NCM_LOCAL_CONF" ]; then
    source "$NCM_LOCAL_CONF"
    if [ -n "$NEXTCLOUD_PATH" ] && [ -f "$NEXTCLOUD_PATH/config/config.php" ]; then
        NEXTCLOUD_CONFIG="$NEXTCLOUD_PATH/config/config.php"
        NEXTCLOUD_CONFIG_FOUND=1
    fi
fi
if [ "$NEXTCLOUD_CONFIG_FOUND" -eq 0 ]; then
    echo "❌ Nextcloud config.php not found! Please set the path in ncm_local.conf."
    exit 1
fi
# Read datadirectory from config
get_nc_config_value() {
    local key="$1"
    if [ -f "$NEXTCLOUD_CONFIG" ]; then
        php -r "include '$NEXTCLOUD_CONFIG'; echo isset($CONFIG['$key']) ? $CONFIG['$key'] : '';" 2>/dev/null
    fi
}
NC_DATADIR="$(get_nc_config_value datadirectory)"
if [ -n "$NC_DATADIR" ] && [ -d "$NC_DATADIR" ]; then
    rm -f "$NC_DATADIR/nextcloud.log"
    echo "✅ Nextcloud logs deleted ($NC_DATADIR/nextcloud.log)"
else
    echo "❌ Nextcloud datadirectory not found!"
fi
