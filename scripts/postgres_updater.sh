#!/bin/bash

# Version: 0.1.1
# Description: PostgreSQL Upgrade Script

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run as root!"
    exit 1
fi

# Determine current PostgreSQL version
current_version=$(psql -V 2>/dev/null | grep -oP '(?<=PostgreSQL )\d+' || echo "")

if [ -z "$current_version" ]; then
    echo "⚠️ PostgreSQL does not seem to be installed!"
    exit 1
fi

echo "📊 Current PostgreSQL Version: $current_version"
read -p "🎯 Which version would you like to upgrade to? (e.g., 17): " target_version

if [ -z "$target_version" ] || ! [[ "$target_version" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid target version!"
    exit 1
fi

echo "🔄 Starting upgrade from PostgreSQL $current_version to version $target_version..."

# 1. Add Repository
echo "📦 Adding PostgreSQL Repository..."
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list

# 2. Import GPG Key
echo "🔑 Importing GPG Key..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/postgresql.gpg > /dev/null

# 3. Update Package List
echo "📋 Updating package list..."
apt-get update

# 4. Install New PostgreSQL Version
echo "⬇️ Installing PostgreSQL $target_version..."
apt-get install -y postgresql-$target_version postgresql-server-dev-$target_version postgresql-contrib-$target_version libpq-dev postgresql-$target_version-hypopg

# 5. Stop PostgreSQL Service
echo "⏸️ Stopping PostgreSQL Service..."
systemctl stop postgresql

# 6. Perform Cluster Upgrade
echo "🔄 Performing cluster upgrade..."
pg_dropcluster $target_version main --stop
pg_upgradecluster $current_version main
pg_dropcluster $current_version main --stop

# 7. Restart PostgreSQL Service
echo "🔄 Restarting PostgreSQL Service..."
systemctl restart postgresql

# Verify New Version
new_version=$(psql -V 2>/dev/null | grep -oP '(?<=PostgreSQL )\d+')
if [ "$new_version" == "$target_version" ]; then
    echo "✅ Upgrade completed successfully! PostgreSQL Version $target_version is now installed."
else
    echo "⚠️ Upgrade might not have been successful. Please verify the installation."
fi