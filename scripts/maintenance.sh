#!/bin/bash
# Version: 0.1.2

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root!"
    exit 1
fi

NEXTCLOUD_PATH="/var/www/nextcloud"

check_nextcloud() {
    if [ ! -d "$NEXTCLOUD_PATH" ]; then
        echo "⚠️ Default Nextcloud path ($NEXTCLOUD_PATH) not found!"
        read -p "Enter your Nextcloud path (e.g., /var/www/html/nextcloud): " custom_path
        if [ -d "$custom_path" ]; then
            NEXTCLOUD_PATH="$custom_path"
        else
            echo "❌ Invalid path. Nextcloud installation not found!"
            exit 1
        fi
    fi
}

run_occ() {
    sudo -u www-data php "$NEXTCLOUD_PATH/occ" "$@"
}

check_nextcloud

mode="$1"

case "$mode" in
    "on")
        echo "⚡ Enabling maintenance mode..."
        run_occ maintenance:mode --on
        echo "✅ Maintenance mode enabled"
        ;;
    "off")
        echo "⚡ Disabling maintenance mode..."
        run_occ maintenance:mode --off
        echo "✅ Maintenance mode disabled"
        ;;
    *)
        echo "❌ Invalid option! Usage: $0 [on|off]"
        exit 1
        ;;
esac