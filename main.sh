#!/bin/bash

REPO_URL="https://github.com/tenbyte/ncm"
RAW_URL="https://raw.githubusercontent.com/tenbyte/ncm/main"
SCRIPTS_DIR="./scripts"
CURRENT_VERSION="0.1.4"

# Colors and styles
CYAN="\033[36m"
WHITE="\033[37m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"
MAGENTA="\033[35m"
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINE="\033[4m"
RESET="\033[0m"
BG_BLUE="\033[44m"

HOSTNAME=$(hostname)

for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] && chmod +x "$script"
done

update_all() {
    echo "🔄 Updating NCM System..."
    
    # Update main script first
    echo "📥 Downloading main script updates..."
    curl -s -o main.sh.tmp "${RAW_URL}/main.sh"
    
    if [ $? -eq 0 ] && [ -f main.sh.tmp ]; then
        chmod +x main.sh.tmp
        mv main.sh.tmp main.sh
        echo "✅ Main script updated"
    else
        echo "❌ Failed to update main script"
        rm -f main.sh.tmp
        return 1
    fi

    [ ! -d "$SCRIPTS_DIR" ] && mkdir -p "$SCRIPTS_DIR"

    echo "📥 Downloading script updates..."
    ONLINE_SCRIPTS=$(curl -s "https://api.github.com/repos/tenbyte/ncm/contents/scripts" | grep '"name"' | awk -F '"' '{print $4}')

    if [ -z "$ONLINE_SCRIPTS" ]; then
        echo "⚠️ Could not fetch scripts!"
        return 1
    fi

    for script in $ONLINE_SCRIPTS; do
        echo "⬇️  Downloading $script..."
        curl -s -o "$SCRIPTS_DIR/$script" "$RAW_URL/scripts/$script"
        chmod +x "$SCRIPTS_DIR/$script"
    done

    echo "✅ Update completed! System will restart..."
    exec ./main.sh
}

check_update() {
    echo "🔄 Checking for updates..."
    LATEST_VERSION=$(curl -s "${RAW_URL}/version.txt" | tr -d '\r')

    if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️ Could not fetch version information!"
        return 1
    fi

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "🚀 Update available: $LATEST_VERSION (current: $CURRENT_VERSION)"
        read -p "Do you want to update? (y/n): " choice
        if [ "$choice" == "y" ]; then
            update_all
        fi
    else
        echo "✅ System is up to date ($CURRENT_VERSION)"
        read -p "Force update anyway? (y/n): " force_choice
        if [ "$force_choice" == "y" ]; then
            update_all
        fi
    fi
}

run_scripts() {
    scripts=($(ls "$SCRIPTS_DIR"/*.sh 2>/dev/null))
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "⚠️ No scripts found!"
        return 1
    fi

    echo "📂 Available scripts:"
    for i in "${!scripts[@]}"; do
        echo "$((i+1))) $(basename "${scripts[$i]}")"
    done

    echo "0) Back to main menu"
    read -p "Choose a script to run: " choice

    if [ "$choice" -eq 0 ]; then
        return 0
    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#scripts[@]} ]; then
        echo "🔄 Starting $(basename "${scripts[$((choice-1))]}")..."
        bash "${scripts[$((choice-1))]}"
        echo -e "\n${YELLOW}Press Enter to return to main menu...${RESET}"
        read
    else
        echo "❌ Invalid input!"
    fi
}

toggle_maintenance() {
    mode="$1"
    if [ "$mode" != "on" ] && [ "$mode" != "off" ]; then
        echo "❌ Invalid maintenance mode!"
        return 1
    fi
    
    bash "$SCRIPTS_DIR/maintenance.sh" "$mode"
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
    
    echo -e "${BG_BLUE}${WHITE}${BOLD} SYSTEM INFORMATION ${RESET}"
    echo -e "${CYAN}╭─────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}Hostname:${RESET} ${GREEN}$HOSTNAME${RESET}        ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}Version:${RESET}  ${YELLOW}v$CURRENT_VERSION${RESET}              ${CYAN}│${RESET}"
    echo -e "${CYAN}╰─────────────────────────────────╯${RESET}"
    echo ""
    
    echo -e "${BG_BLUE}${WHITE}${BOLD} MAIN MENU ${RESET}"
    echo -e "${CYAN}╭─────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}1)${RESET} ${WHITE}Check for Updates${RESET}             ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}2)${RESET} ${WHITE}Scripts Manager${RESET}              ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}3)${RESET} ${GREEN}Enable Maintenance Mode${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}4)${RESET} ${RED}Disable Maintenance Mode${RESET}     ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET} ${BOLD}5)${RESET} ${YELLOW}Exit${RESET}                        ${CYAN}│${RESET}"
    echo -e "${CYAN}╰─────────────────────────────────╯${RESET}"
    
    echo -e "\n${DIM}Enter your choice [1-5]:${RESET} "
    read -p "" choice

    case $choice in
        1) check_update ;;
        2) run_scripts ;;
        3) toggle_maintenance "on" ;;
        4) toggle_maintenance "off" ;;
        5) 
           echo -e "\n${YELLOW}Goodbye!${RESET}"
           exit 0 
           ;;
        *) 
           echo -e "\n${RED}❌ Invalid input!${RESET}"
           sleep 2
           ;;
    esac
}

while true; do
    show_menu
    if [ $? -ne 0 ]; then
        echo -e "\n${DIM}Press Enter to continue...${RESET}"
        read
    fi
done
