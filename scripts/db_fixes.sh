#!/bin/bash
# Version: 0.1.3

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

echo "🔧 Nextcloud Maintenance Script"
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