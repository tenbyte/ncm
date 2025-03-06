#!/bin/bash
# Version: 0.1.0

LOG_FILE="/var/log/php8.3_install.log"

echo "🔄 PHP 8.3 Installations- und Konfigurationsskript für Nextcloud"
echo "================================================================="
echo "ℹ️  Dieses Skript installiert PHP 8.3 und passt die Konfiguration für Nextcloud an."

# === Sicherstellen, dass Root-Rechte vorhanden sind ===
if [[ $EUID -ne 0 ]]; then
   echo "❌ Dieses Skript muss als Root ausgeführt werden!" 
   exit 1
fi

# === Logging Funktion ===
log() {
    echo "$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# === System aktualisieren ===
log "🔄 Systemupdate wird durchgeführt..."
apt update && apt -y upgrade && apt -y autoremove

# === PHP Repository hinzufügen ===
log "🔄 PHP Repository von Ondrej wird hinzugefügt..."
apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update


# === MariaDB oder PostgreSQL wählen ===
echo "Welche Datenbank nutzt dein Nextcloud-Setup?"
echo "1) MariaDB/MySQL"
echo "2) PostgreSQL"
read -r DB_CHOICE

# === PHP 8.3 installieren (je nach DB-Variante) ===
if [[ "$DB_CHOICE" == "1" ]]; then
    log "📦 Installiere PHP 8.3 für MariaDB/MySQL..."
    apt install -y php-common php8.3-{fpm,gd,curl,xml,zip,intl,mbstring,bz2,ldap,apcu,bcmath,gmp,imagick,igbinary,mysql,redis,smbclient,sqlite3,cli,common,opcache,readline} imagemagick libmagickcore-6.q16-6-extra --allow-change-held-packages
elif [[ "$DB_CHOICE" == "2" ]]; then
    log "📦 Installiere PHP 8.3 für PostgreSQL..."
    apt install -y php-common php8.3-{fpm,gd,curl,xml,zip,intl,mbstring,bz2,ldap,apcu,bcmath,gmp,imagick,igbinary,pgsql,redis,smbclient,sqlite3,cli,common,opcache,readline} imagemagick libmagickcore-6.q16-6-extra --allow-change-held-packages
else
    log "❌ Ungültige Eingabe! Breche ab."
    exit 1
fi

# === Sicherstellen, dass die Zeitzone korrekt gesetzt ist ===
log "🕒 Setze Zeitzone auf Europe/Berlin..."
timedatectl set-timezone Europe/Berlin

# === PHP 8.3 Optimierung ===
log "🛠  Konfiguriere PHP 8.3 für Nextcloud..."

# Backup erstellen
log "📂 Erstelle Backups aller relevanten PHP 8.3 Konfigurationsdateien..."
cp /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.bak
cp /etc/php/8.3/fpm/php-fpm.conf /etc/php/8.3/fpm/php-fpm.conf.bak
cp /etc/php/8.3/cli/php.ini /etc/php/8.3/cli/php.ini.bak
cp /etc/php/8.3/fpm/php.ini /etc/php/8.3/fpm/php.ini.bak
cp /etc/php/8.3/mods-available/apcu.ini /etc/php/8.3/mods-available/apcu.ini.bak
cp /etc/php/8.3/mods-available/opcache.ini /etc/php/8.3/mods-available/opcache.ini.bak
cp /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.bak


# Anpassungen
log "📌 Passen PHP-FPM Parameter an..."
sed -i "s/;env\[HOSTNAME\] = /env[HOSTNAME] = /" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/;env\[TMP\] = /env[TMP] = /" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/;env\[TMPDIR\] = /env[TMPDIR] = /" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/;env\[TEMP\] = /env[TEMP] = /" /etc/php/8.3/fpm/pool.d/www.conf
sed -i "s/;env\[PATH\] = /env[PATH] = /" /etc/php/8.3/fpm/pool.d/www.conf
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
sed -i "s/memory_limit = 128M/memory_limit = 1G/" /etc/php/8.3/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.3/fpm/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.3/fpm/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.3/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10G/" /etc/php/8.3/fpm/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10G/" /etc/php/8.3/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.3/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/8.3/fpm/php.ini
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


# === MariaDB / MySQL Konfiguration anpassen ===
if [[ "$DB_CHOICE" == "1" ]]; then
    log "🔧 Passe MySQL/MariaDB PHP 8.3 Konfiguration an..."

    if [ -f "/etc/php/8.3/mods-available/mysqli.ini" ]; then
        cp /etc/php/8.3/mods-available/mysqli.ini /etc/php/8.3/mods-available/mysqli.ini.bak
        grep -qxF "[mysql]" /etc/php/8.3/mods-available/mysqli.ini || echo "[mysql]" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.allow_local_infile=On" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.allow_local_infile=On" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.allow_persistent=On" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.allow_persistent=On" >> /etc/php/8.3/mods-available/mysqli.ini
        grep -qxF "mysql.cache_size=2000" /etc/php/8.3/mods-available/mysqli.ini || echo "mysql.cache_size=2000" >> /etc/php/8.3/mods-available/mysqli.ini
        log "✅ MySQL/MariaDB Konfiguration angepasst!"
    else
        log "⚠️  mysqli.ini nicht gefunden! Überspringe MariaDB-Konfiguration."
    fi
fi

# === PostgreSQL Konfiguration anpassen ===
if [[ "$DB_CHOICE" == "2" ]]; then
    log "🔧 Passe PostgreSQL PHP 8.3 Konfiguration an..."

    if [ -f "/etc/php/8.3/mods-available/pgsql.ini" ]; then
        cp /etc/php/8.3/mods-available/pgsql.ini /etc/php/8.3/mods-available/pgsql.ini.bak
        grep -qxF "[PostgreSQL]" /etc/php/8.3/mods-available/pgsql.ini || echo "[PostgreSQL]" >> /etc/php/8.3/mods-available/pgsql.ini
        grep -qxF "pgsql.allow_persistent = On" /etc/php/8.3/mods-available/pgsql.ini || echo "pgsql.allow_persistent = On" >> /etc/php/8.3/mods-available/pgsql.ini
        grep -qxF "pgsql.auto_reset_persistent = Off" /etc/php/8.3/mods-available/pgsql.ini || echo "pgsql.auto_reset_persistent = Off" >> /etc/php/8.3/mods-available/pgsql.ini
        log "✅ PostgreSQL Konfiguration angepasst!"
    else
        log "⚠️  pgsql.ini nicht gefunden! Überspringe PostgreSQL-Konfiguration."
    fi
fi


# === Apache oder Nginx erkennen ===
WEB_SERVER=""
if command -v apache2 &> /dev/null; then
    WEB_SERVER="apache"
elif command -v nginx &> /dev/null; then
    WEB_SERVER="nginx"
else
    log "⚠️  Kein Webserver erkannt! Bitte manuell prüfen."
fi

# === Interaktive Abfrage der vorherigen PHP-Version ===
echo "Welche PHP-Version wurde vorher genutzt? (z.B. 8.2)"
read -r OLD_PHP_VERSION

if [ -z "$OLD_PHP_VERSION" ]; then
    log "⚠️  Keine vorherige PHP-Version eingegeben. Bitte manuell prüfen."
    exit 1
fi

# === Nextcloud PHP-FPM Pool für Apache anpassen ===
if [[ "$WEB_SERVER" == "apache" ]]; then
    log "📂 Kopiere und aktualisiere Nextcloud PHP-FPM Pool von $OLD_PHP_VERSION auf 8.3..."

    if [ -f "/etc/php/$OLD_PHP_VERSION/fpm/pool.d/nextcloud.conf" ]; then
        cp "/etc/php/$OLD_PHP_VERSION/fpm/pool.d/nextcloud.conf" "/etc/php/8.3/fpm/pool.d/nextcloud.conf"
        sed -i "s/php$OLD_PHP_VERSION-fpm.nextcloud.sock/php8.3-fpm.nextcloud.sock/g" /etc/php/8.3/fpm/pool.d/nextcloud.conf
    else
        log "⚠️  Keine bestehende Nextcloud PHP-FPM Konfiguration für PHP $OLD_PHP_VERSION gefunden!"
    fi

    # Apache Nextcloud Konfigurationsdatei anpassen
    APACHE_CONFIG="/etc/apache2/sites-enabled/nextcloud.conf"
    if [ -f "$APACHE_CONFIG" ]; then
        sed -i "s/php$OLD_PHP_VERSION-fpm.nextcloud.sock/php8.3-fpm.nextcloud.sock/g" "$APACHE_CONFIG"
        log "✅ Apache Nextcloud-Konfiguration wurde angepasst!"
    else
        log "⚠️  Keine Apache Nextcloud-Konfiguration gefunden. Bitte manuell überprüfen!"
    fi
fi

# === Nginx PHP-FPM Sockets anpassen ===
if [[ "$WEB_SERVER" == "nginx" ]]; then
    log "🔧 Passe PHP-FPM Socket für Nginx an..."
    NGINX_CONF="/etc/nginx/conf.d/http.conf"
    
    if [ -f "$NGINX_CONF" ]; then
        sed -i "s/php$OLD_PHP_VERSION-fpm.sock/php8.3-fpm.sock/g" "$NGINX_CONF"
        log "✅ Nginx Konfiguration wurde angepasst!"
    else
        log "⚠️  Keine Nginx-Konfigurationsdatei gefunden. Bitte manuell überprüfen!"
    fi
fi

# === Nextcloud PHP-FPM Pool (nextcloud.conf oder domain.conf) anpassen ===
log "📂 Aktualisiere PHP-FPM Pool Konfigurationsdateien für Nextcloud..."
PHP_FPM_POOL_CONF="/etc/php/8.3/fpm/pool.d/nextcloud.conf"
DOMAIN_CONF=$(find /etc/php/8.3/fpm/pool.d/ -name "*.conf" | grep -Ev "www.conf|nextcloud.conf")

if [ -f "$PHP_FPM_POOL_CONF" ]; then
    sed -i "s/php$OLD_PHP_VERSION-fpm.nextcloud.sock/php8.3-fpm.nextcloud.sock/g" "$PHP_FPM_POOL_CONF"
    log "✅ `nextcloud.conf` wurde aktualisiert."
fi

if [ -n "$DOMAIN_CONF" ]; then
    sed -i "s/php$OLD_PHP_VERSION-fpm.nextcloud.sock/php8.3-fpm.nextcloud.sock/g" "$DOMAIN_CONF"
    log "✅ `$(basename "$DOMAIN_CONF")` wurde aktualisiert."
fi


# === Webserver und PHP-FPM neu starten ===
if [[ "$WEB_SERVER" == "apache" ]]; then
    log "♻️  Starte Apache mit PHP 8.3 neu..."
    systemctl restart php8.3-fpm.service apache2.service
elif [[ "$WEB_SERVER" == "nginx" ]]; then
    log "♻️  Starte Nginx mit PHP 8.3 neu..."
    systemctl restart php8.3-fpm.service nginx.service
fi


log "✅ PHP 8.3 Installation & Konfiguration abgeschlossen!"
echo "✅ PHP 8.3 wurde erfolgreich installiert und konfiguriert!"
echo "⚠️  Bei Fehlern folgende configs und Versionen überprüfen. Apache: /etc/apache2/sites-enabled & /etc/php/8.3/fpm/pool.d/"
