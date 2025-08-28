#!/bin/bash
# Version: 0.1.5

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
NC_DATADIR="$(get_nc_config_value datadirectory)"
if [ -n "$NC_DATADIR" ] && [ -d "$NC_DATADIR" ]; then
    rm -f "$NC_DATADIR/nextcloud.log"
    echo "✅ Nextcloud logs deleted ($NC_DATADIR/nextcloud.log)"
else
    echo "❌ Nextcloud datadirectory not found!"
fi
