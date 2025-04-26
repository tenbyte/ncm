#!/bin/bash

# Version: 0.1.4

LOG_FILE="/var/log/php8.3_install.log"

echo "🔄 PHP 8.3 Installation and Configuration Script for Nextcloud"
echo "================================================================="
echo "ℹ️  This script will install PHP 8.3"

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root!" 
   exit 1
fi

log() {
    echo "$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log "🔄 Performing system update..."
apt update && apt -y upgrade && apt -y autoremove

log "🔄 Adding PHP repository from Ondrej..."
apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update

log "🧹 Removing potentially conflicting packages..."
apt remove -y php-imagick imagemagick php8.*-imagick || true
apt autoremove -y

log "🔄 Installing ImageMagick..."
apt install -y imagemagick libmagickcore-6.q16-6-extra

echo "Which database does your Nextcloud setup use?"
echo "1) MariaDB/MySQL"
echo "2) PostgreSQL"
read -r DB_CHOICE

if [[ "$DB_CHOICE" == "1" ]]; then
    log "📦 Installing PHP 8.3 for MariaDB/MySQL..."
    apt install -y php8.3-fpm php8.3-gd php8.3-curl php8.3-xml php8.3-zip php8.3-intl php8.3-mbstring php8.3-bz2 php8.3-ldap php8.3-apcu php8.3-bcmath php8.3-gmp php8.3-igbinary php8.3-mysql php8.3-redis php8.3-smbclient php8.3-sqlite3 php8.3-cli php8.3-common php8.3-opcache php8.3-readline
elif [[ "$DB_CHOICE" == "2" ]]; then
    log "📦 Installing PHP 8.3 for PostgreSQL..."
    apt install -y php8.3-fpm php8.3-gd php8.3-curl php8.3-xml php8.3-zip php8.3-intl php8.3-mbstring php8.3-bz2 php8.3-ldap php8.3-apcu php8.3-bcmath php8.3-gmp php8.3-igbinary php8.3-pgsql php8.3-redis php8.3-smbclient php8.3-sqlite3 php8.3-cli php8.3-common php8.3-opcache php8.3-readline
else
    log "❌ Invalid input! Aborting."
    exit 1
fi

log "📦 Installing PHP-Imagick..."
apt install -y php8.3-imagick

# Check if Apache is installed before trying to enable PHP module
if command -v apache2 >/dev/null 2>&1; then
    log "🛠 Configuring PHP 8.3 for Apache..."
    a2dismod php* || true
    a2enmod php8.3 || true
    systemctl restart apache2 || true
fi

# Check which web server is installed
if command -v apache2 >/dev/null 2>&1; then
    WEB_SERVER="apache"
elif command -v nginx >/dev/null 2>&1; then
    WEB_SERVER="nginx"
fi

if update-alternatives --config php | grep -q "/usr/bin/php8.3"; then
    log "✅ PHP 8.3 has been successfully set as default."
else
    log "⚠️ PHP 8.3 could not be set as default automatically!"
fi


log "🕒 Setting timezone to Europe/Berlin..."
timedatectl set-timezone Europe/Berlin

log "🛠  Configuring PHP 8.3 for Nextcloud..."
sudo a2enmod php8.3 

log "📂 Creating backups of all relevant PHP 8.3 configuration files..."
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.bak
cp /etc/php/8.3/fpm/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf.bak
cp /etc/php/8.3/cli/php.ini /etc/php/8.3/cli/php.ini.bak
cp /etc/php/8.3/fpm/php.ini /etc/php/8.3/fpm/php.ini.bak
cp /etc/php/8.3/mods-available/apcu.ini /etc/php/8.3/mods-available/apcu.ini.bak
cp /etc/php/8.3/mods-available/opcache.ini /etc/php/8.3/mods-available/opcache.ini.bak
cp /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.bak


log "📌 Adjusting PHP-FPM parameters..."
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.max_children =.*/pm.max_children = 200/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.start_servers =.*/pm.start_servers = 100/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.min_spare_servers =.*/pm.min_spare_servers = 60/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/pm.max_spare_servers =.*/pm.max_spare_servers = 140/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/;pm.max_requests =.*/pm.max_requests = 1000/" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/allow_url_fopen =.*/allow_url_fopen = 1/" /etc/php/8.3/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.3/cli/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.3/cli/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.3/cli/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/8.3/cli/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/8.3/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.3/cli/php.ini
sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/8.3/cli/php.ini
sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=256/" /etc/php/8.3/cli/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 1G/" /etc/php/8.3/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.3/fpm/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.3/fpm/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.3/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10G/" /etc/php/8.3/fpm/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10G/" /etc/php/8.3/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.3/fpm/php.ini
sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=256/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=64/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=100000/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php/8.3/fpm/php.ini
sed -i "s/;opcache.huge_code_pages=.*/opcache.huge_code_pages=0/" /etc/php/8.3/fpm/php.ini
sed -i "s|;emergency_restart_threshold.*|emergency_restart_threshold = 10|g" /etc/php/8.3/fpm/php-fpm.conf
sed -i "s|;emergency_restart_interval.*|emergency_restart_interval = 1m|g" /etc/php/8.3/fpm/php-fpm.conf
sed -i "s|;process_control_timeout.*|process_control_timeout = 10|g" /etc/php/8.3/fpm/php-fpm.conf
sed -i '$aapc.enable_cli=1' /etc/php/8.3/mods-available/apcu.ini
sed -i 's/opcache.jit=off/opcache.jit=on/' /etc/php/8.3/mods-available/opcache.ini
sed -i '$aopcache.jit=1255' /etc/php/8.3/mods-available/opcache.ini
sed -i '$aopcache.jit_buffer_size=256M' /etc/php/8.3/mods-available/opcache.ini
sed -i "s/rights=\"none\" pattern=\"PS\"/rights=\"read|write\" pattern=\"PS\"/" /etc/ImageMagick-6/policy.xml
sed -i "s/rights=\"none\" pattern=\"EPS\"/rights=\"read|write\" pattern=\"EPS\"/" /etc/ImageMagick-6/policy.xml
sed -i "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/" /etc/ImageMagick-6/policy.xml
sed -i "s/rights=\"none\" pattern=\"XPS\"/rights=\"read|write\" pattern=\"XPS\"/" /etc/ImageMagick-6/policy.xml


if [[ "$DB_CHOICE" == "1" ]]; then
    log "🔧 Adjusting MySQL/MariaDB PHP 8.3 configuration..."

    if [ -f "/etc/php/8.3/mods-available/mysqli.ini" ]; then
        cp /etc/php/8.3/mods-available/mysqli.ini /etc/php/8.3/mods-available/mysqli.ini.bak
        grep -qxF "[mysql]" /etc/php/8.3/mods-available/mysqli.ini || echo "[mysql]" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.allow_local_infile=On" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.allow_local_infile=On" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.allow_persistent=On" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.allow_persistent=On" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.cache_size=2000" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.cache_size=2000" >> /etc/php/8.3/mods-available/mysqli.ini
        log "✅ MySQL/MariaDB configuration adjusted!"
    else
        log "⚠️  mysqli.ini not found! Skipping MariaDB configuration."
    fi
fi


if [[ "$DB_CHOICE" == "2" ]]; then
    log "🔧 Adjusting PostgreSQL PHP 8.3 configuration..."

    if [ -f "/etc/php/8.3/mods-available/pgsql.ini" ]; then
        cp /etc/php/8.3/mods-available/pgsql.ini /etc/php/8.3/mods-available/pgsql.ini.bak
        grep -qxF "[PostgreSQL]" /etc/php/8.3/mods-available/pgsql.ini || echo "[PostgreSQL]" >> /etc/php/8.3/mods-available/pgsql.ini
        grep -qxF "pgsql.allow_persistent = On" /etc/php/8.3/mods-available/pgsql.ini || echo "pgsql.allow_persistent = On" >> /etc/php/8.3/mods-available/pgsql.ini
        grep -qxF "pgsql.auto_reset_persistent = Off" /etc/php/8.3/mods-available/pgsql.ini || echo "pgsql.auto_reset_persistent = Off" >> /etc/php/8.3/mods-available/pgsql.ini
        log "✅ PostgreSQL configuration adjusted!"
    else
        log "⚠️  pgsql.ini not found! Skipping PostgreSQL configuration."
    fi
fi


log "🛠 Setting PHP 8.3 as default..."
update-alternatives --set php /usr/bin/php8.3
update-alternatives --set phar /usr/bin/phar8.3
update-alternatives --set phar.phar /usr/bin/phar.phar8.3
update-alternatives --set phpize /usr/bin/phpize8.3
update-alternatives --set php-config /usr/bin/php-config8.3


log "🔍 Checking if PHP-FPM and webserver are running successfully..."
if ! systemctl is-active --quiet php8.3-fpm.service; then
    log "❌ Error: PHP-FPM could not be started!"
    echo "⚠️ PHP-FPM could not be started! Check the logs:"
    echo "🔹 journalctl -xe -u php8.3-fpm.service"
    echo "🔹 cat /var/log/php8.3-fpm.log"
    exit 1
fi

if [[ "$WEB_SERVER" == "apache" ]]; then
    if ! systemctl is-active --quiet apache2.service; then
        log "❌ Error: Apache could not be started!"
        echo "⚠️ Apache could not be started! Check the logs:"
        echo "🔹 journalctl -xe -u apache2.service"
        echo "🔹 cat /var/log/apache2/error.log"
        exit 1
    fi
fi

if [[ "$WEB_SERVER" == "nginx" ]]; then
    if ! systemctl is-active --quiet nginx.service; then
        log "❌ Error: Nginx could not be started!"
        echo "⚠️ Nginx could not be started! Check the logs:"
        echo "🔹 journalctl -xe -u nginx.service"
        echo "🔹 cat /var/log/nginx/error.log"
        exit 1
    fi
fi


log "✅ PHP 8.3 installation completed!"
echo "✅ PHP 8.3 has been successfully installed"
echo "⚠️  You have to update the version in the following configs: Apache: /etc/apache2/sites-enabled & /etc/php/8.3/fpm/pool.d/"

echo -e "\n${YELLOW}Press Enter to return to main menu...${RESET}"
read