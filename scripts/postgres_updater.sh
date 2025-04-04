#!/bin/bash
# Version: 0.1.3

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

echo -e "\n${RED}⚠️  IMPORTANT WARNING ⚠️${RESET}"
echo "────────────────────────"
echo "🔴 This process will:"
echo "   1. Upgrade PostgreSQL from version $current_version to version $target_version"
echo "   2. Migrate all databases"
echo "   3. Drop the old cluster after successful migration"
echo ""
echo "💾 PLEASE ENSURE YOU HAVE A BACKUP OF YOUR DATABASES!"
echo ""
read -p "Do you have a current backup? (Type y to proceed): " backup_confirm
if [ "$backup_confirm" != "y" ]; then
    echo "❌ Aborted: Please create a backup first!"
    exit 1
fi

read -p "Are you sure you want to proceed with the upgrade? (Type y to proceed): " upgrade_confirm
if [ "$upgrade_confirm" != "y" ]; then
    echo "❌ Upgrade aborted!"
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

echo -e "\n${RED}⚠️  FINAL WARNING ⚠️${RESET}"
echo "────────────────────────"
echo "🔴 New PostgreSQL $target_version is installed."
echo "🔴 The next step will migrate databases and drop the old cluster."
echo ""
read -p "Last chance to abort. Proceed? (Type y): " final_confirm
if [ "$final_confirm" != "y" ]; then
    echo "❌ Upgrade aborted!"
    exit 1
fi

echo "⏸️ Stopping PostgreSQL Service..."
systemctl stop postgresql

echo "🔄 Performing cluster upgrade..."
read -p "About to drop cluster $target_version. Continue? (y/n): " drop_confirm
if [ "$drop_confirm" != "y" ]; then
    echo "❌ Upgrade aborted!"
    exit 1
fi
pg_dropcluster $target_version main --stop

echo "🔄 Upgrading cluster..."
read -p "About to upgrade cluster from $current_version to $target_version. Continue? (y/n): " upgrade_cluster_confirm
if [ "$upgrade_cluster_confirm" != "y" ]; then
    echo "❌ Upgrade aborted!"
    exit 1
fi
pg_upgradecluster $current_version main

echo "🔄 Dropping old cluster..."
read -p "About to drop old cluster $current_version. Continue? (y/n): " drop_old_confirm
if [ "$drop_old_confirm" != "y" ]; then
    echo "❌ Old cluster removal aborted!"
    exit 1
fi
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

echo -e "\n${YELLOW}Press Enter to return to main menu...${RESET}"
read