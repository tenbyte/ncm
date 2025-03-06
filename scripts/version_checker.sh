#!/bin/bash
# Version: 0.1.0

echo "🔍 NCM - Version Checker"
echo "========================================="

# === Nextcloud Version ===
NEXTCLOUD_PATHS=(
    "/var/www/html/nextcloud"
    "/var/www/nextcloud"
)

NC_VERSION="Nicht gefunden"
for path in "${NEXTCLOUD_PATHS[@]}"; do
    if [ -f "$path/version.php" ]; then
        NC_VERSION=$(grep "'version'" "$path/version.php" | awk -F "'" '{print $4}')
        echo "📌 Nextcloud Version: $NC_VERSION ($path)"
        break
    fi
done

if [ "$NC_VERSION" == "Nicht gefunden" ]; then
    echo "⚠️ Nextcloud nicht gefunden!"
fi

# === PHP Version ===
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}')
    echo "📌 PHP Version: $PHP_VERSION"
else
    echo "⚠️ PHP nicht installiert!"
fi

# === MySQL / MariaDB Version (Server & Client) ===
if command -v mysql &> /dev/null; then
    MYSQL_SERVER_VERSION=$(mysql -V | awk '{print $5}' | tr -d ",")
    echo "📌 MySQL Server Version: $MYSQL_SERVER_VERSION"
elif command -v mariadb &> /dev/null; then
    MARIADB_SERVER_VERSION=$(mariadb --version | awk '{print $5}' | tr -d ",")
    echo "📌 MariaDB Server Version: $MARIADB_SERVER_VERSION"
else
    echo "⚠️ MySQL/MariaDB Server nicht gefunden!"
fi

if command -v mysqladmin &> /dev/null; then
    MYSQL_CLIENT_VERSION=$(mysqladmin -V | awk '{print $4}' | tr -d ",")
    echo "📌 MySQL/MariaDB Client Version: $MYSQL_CLIENT_VERSION"
fi

# === PostgreSQL Version ===
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql -V | awk '{print $3}')
    echo "📌 PostgreSQL Version: $PG_VERSION"
else
    echo "⚠️ PostgreSQL nicht installiert!"
fi

# === Webserver (Apache oder Nginx) ===
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
    echo "⚠️ Nginx nicht installiert!"
fi

echo "========================================="
