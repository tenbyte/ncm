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
sudo -u www-data php "$NEXTCLOUD_PATH/occ" maintenance:mode --on
