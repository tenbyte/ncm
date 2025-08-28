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

echo "🔍 NCM - Version Checker"
echo "========================================="

if [ "$NEXTCLOUD_CONFIG_FOUND" -eq 1 ]; then
    NC_VERSION="$(get_nc_config_value version)"
    if [ -n "$NC_VERSION" ]; then
        echo "📌 Nextcloud Version: $NC_VERSION ($NEXTCLOUD_PATH)"
    else
        echo "⚠️ Nextcloud Version not found in config!"
    fi
else
    echo "⚠️ Nextcloud config.php not found!"
fi

if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}')
    echo "📌 PHP Version: $PHP_VERSION"
else
    echo "⚠️ PHP not installed!"
fi

if command -v mysql &> /dev/null; then
    MYSQL_SERVER_VERSION=$(mysql -V | awk '{print $5}' | tr -d ",")
    echo "📌 MySQL Server Version: $MYSQL_SERVER_VERSION"
elif command -v mariadb &> /dev/null; then
    MARIADB_SERVER_VERSION=$(mariadb --version | awk '{print $5}' | tr -d ",")
    echo "📌 MariaDB Server Version: $MARIADB_SERVER_VERSION"
else
    echo "⚠️ MySQL/MariaDB Server not found!"
fi

if command -v mysqladmin &> /dev/null; then
    MYSQL_CLIENT_VERSION=$(mysqladmin -V | awk '{print $4}' | tr -d ",")
    echo "📌 MySQL/MariaDB Client Version: $MYSQL_CLIENT_VERSION"
fi

if command -v psql &> /dev/null; then
    PG_VERSION=$(psql -V | awk '{print $3}')
    echo "📌 PostgreSQL Version: $PG_VERSION"
else
    echo "⚠️ PostgreSQL not installed!"
fi

if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | grep "Server version" | awk '{print $3}')
    echo "📌 Apache Version: $APACHE_VERSION"
elif command -v httpd &> /dev/null; then
    APACHE_VERSION=$(httpd -v | grep "Server version" | awk '{print $3}')
    echo "📌 Apache Version (RHEL): $APACHE_VERSION"
fi

if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print "📌 Nginx Version: " $2}')
    echo "$NGINX_VERSION"
else
    echo "⚠️ Nginx not installed!"
fi

echo "========================================="

echo -e "\n${YELLOW}Press Enter to return to main menu...${RESET}"
read