#!/bin/bash

# Version: 0.1.2
# Description: PostgreSQL Upgrade Script

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root!"
    exit 1
fi

check_postgres_version() {
    
    if command -v psql &> /dev/null; then
        version=$(psql -V 2>/dev/null | grep -oP '(?<=PostgreSQL )\d+' || echo "")
        if [ ! -z "$version" ]; then
            echo "$version"
            return 0
        fi
    fi

    
    if pgrep postgres &> /dev/null || pgrep postgresql &> /dev/null; then
        for ver in $(ls /etc/postgresql/); do
            if [ -d "/etc/postgresql/$ver" ]; then
                echo "$ver"
                return 0
            fi
        done
    fi

    
    for ver in $(ls /etc/postgresql/ 2>/dev/null); do
        if [ -d "/etc/postgresql/$ver" ]; then
            echo "$ver"
            return 0
        fi
    done

    return 1
}

current_version=$(check_postgres_version)

if [ -z "$current_version" ]; then
    echo "⚠️ Could not detect PostgreSQL version automatically!"
    echo "Available PostgreSQL installations:"
    ls -l /etc/postgresql/ 2>/dev/null
    read -p "Please enter your current PostgreSQL version (e.g., 12): " current_version
    
    if [ -z "$current_version" ] || ! [[ "$current_version" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid version number!"
        exit 1
    fi
fi

echo "📊 Current PostgreSQL Version: $current_version"
read -p "🎯 Which version would you like to upgrade to? (e.g., 17): " target_version

if [ -z "$target_version" ] || ! [[ "$target_version" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid target version!"
    exit 1
fi

echo "🔄 Starting upgrade from PostgreSQL $current_version to version $target_version..."

echo "📦 Adding PostgreSQL Repository..."
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list

echo "🔑 Importing GPG Key..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/postgresql.gpg > /dev/null

echo "📋 Updating package list..."
apt-get update

echo "⬇️ Installing PostgreSQL $target_version..."
apt-get install -y postgresql-$target_version postgresql-server-dev-$target_version postgresql-contrib-$target_version libpq-dev postgresql-$target_version-hypopg

echo "⏸️ Stopping PostgreSQL Service..."
systemctl stop postgresql

echo "🔄 Performing cluster upgrade..."
pg_dropcluster $target_version main --stop
pg_upgradecluster $current_version main
pg_dropcluster $current_version main --stop


echo "🔄 Restarting PostgreSQL Service..."
systemctl restart postgresql


new_version=$(check_postgres_version)
if [ "$new_version" == "$target_version" ]; then
    echo "✅ Upgrade completed successfully! PostgreSQL Version $target_version is now installed."
else
    echo "⚠️ Upgrade might not have been successful. Please verify the installation."
    echo "Current version detected: $new_version"
    echo "Expected version: $target_version"
fi