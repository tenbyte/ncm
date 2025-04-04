#!/bin/bash

REPO_URL="https://github.com/tenbyte/ncm"
RAW_URL="https://raw.githubusercontent.com/tenbyte/ncm/main"
SCRIPTS_DIR="./scripts"
CURRENT_VERSION="0.1.1"

CYAN="\033[36m"
WHITE="\033[0m"
BOLD="\033[1m"
RESET="\033[0m"

for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] && chmod +x "$script"
done

update_all() {
    echo "🔄 Updating all scripts from GitHub..."

    curl -s -o main.sh "${RAW_URL}/main.sh" && chmod +x main.sh

    [ ! -d "$SCRIPTS_DIR" ] && mkdir -p "$SCRIPTS_DIR"

    ONLINE_SCRIPTS=$(curl -s "https://api.github.com/repos/tenbyte/ncm/contents/scripts" | grep '"name"' | awk -F '"' '{print $4}')

    if [ -z "$ONLINE_SCRIPTS" ]; then
        echo "⚠️ Could not fetch online scripts!"
        return
    fi

    for script in $ONLINE_SCRIPTS; do
        echo "⬇️  Downloading $script..."
        curl -s -o "$SCRIPTS_DIR/$script" "$RAW_URL/scripts/$script"
        chmod +x "$SCRIPTS_DIR/$script"
    done

    echo "✅ Update completed! Please restart the script."
    exit 0
}

check_update() {
    echo "🔄 Checking for main script updates..."
    LATEST_VERSION=$(curl -s "${RAW_URL}/version.txt" | tr -d '\r')

    if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️ Could not fetch version information!"
        return
    fi

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "🚀 Update available: $LATEST_VERSION (current: $CURRENT_VERSION)"
        echo "Do you want to update the entire script package? (y/n)"
        read -r choice
        if [ "$choice" == "y" ]; then
            update_all
        fi
    else
        echo "✅ You are using the latest version ($CURRENT_VERSION)."
    fi

    echo "⚠️ Do you want to perform a force update anyway? (y/n)"
    read -r force_choice
    if [ "$force_choice" == "y" ]; then
        update_all
    fi
}

run_local_script() {
    scripts=($(ls "$SCRIPTS_DIR"/*.sh 2>/dev/null))
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "⚠️ No local scripts found!"
        return
    fi

    echo "📂 Available local scripts:"
    for i in "${!scripts[@]}"; do
        echo "$((i+1))) $(basename "${scripts[$i]}")"
    done

    echo "0) Back to main menu"
    read -p "Choose a script to run: " choice

    if [ "$choice" -eq 0 ]; then
        return
    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#scripts[@]} ]; then
        echo "🔄 Starting $(basename "${scripts[$((choice-1))]}")..."
        bash "${scripts[$((choice-1))]}"
    else
        echo "❌ Invalid input!"
    fi
}

list_online_scripts() {
    echo "🌍 Checking online scripts & local versions..."
    
    VERSION_DATA=$(curl -s "$RAW_URL/scripts/version.txt")

    if [ -z "$VERSION_DATA" ]; then
        echo "⚠️ Could not fetch online version file!"
        return
    fi

    echo -e "📂 Comparing local vs. online scripts:"
    echo "--------------------------------------"

    echo "$VERSION_DATA" | while IFS="=" read -r script version_online; do
        local_script="$SCRIPTS_DIR/$script"

        if [ -f "$local_script" ]; then
            version_local=$(grep -E "^# Version: " "$local_script" | awk '{print $3}')

            if [ -z "$version_local" ]; then
                version_local="Unknown"
            fi

            if [ "$version_local" == "$version_online" ]; then
                echo -e "✅ \e[32m$script (Version: $version_local) is up to date\e[0m"
            else
                echo -e "🔄 \e[33m$script (Local: $version_local, Online: $version_online) - Update available!\e[0m"
            fi
        else
            echo -e "❌ \e[31m$script missing locally! (Online: $version_online)\e[0m"
        fi
    done
}

show_menu() {
    clear
    echo -e "${CYAN}  __ ${RESET}${WHITE}    _             _           _       "
    echo -e "${CYAN}  \ \ ${RESET}${WHITE}  | |_ ___ _ __ | |__  _   _| |_ ___ "
    echo -e "${CYAN}   \ \ ${RESET}${WHITE} | __/ _ \ '_ \| '_ \| | | | __/ _ \\"
    echo -e "${CYAN}   / / ${RESET}${WHITE} | ||  __/ | | | |_) | |_| | ||  __/"
    echo -e "${CYAN}  /_/ ${RESET}${WHITE}   \__\___|_| |_|_.__/ \\__, |\\__\\___|"
    echo -e "                            |___/         ${RESET}"
    echo -e ""
    echo -e "${BOLD}${CYAN}       POWERED BY TENBYTE ${RESET}\n"
    echo "==============================="
    echo " NCM by Tenbyte v$CURRENT_VERSION"
    echo "==============================="
    echo "1) Check for updates & update all scripts"
    echo "2) Show & run local scripts"
    echo "3) Check online available scripts"
    echo "4) Exit"
    echo "==============================="
    read -p "Choose an option: " choice

    case $choice in
        1) check_update ;;
        2) run_local_script ;;
        3) list_online_scripts ;;
        4) exit 0 ;;
        *) echo "Invalid input!" ;;
    esac
}

while true; do
    show_menu
    read -p "Press Enter to continue..." 
done
