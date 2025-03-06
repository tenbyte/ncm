#!/bin/bash

REPO_URL="https://github.com/tenbyte/ncm"
RAW_URL="https://raw.githubusercontent.com/tenbyte/ncm/main"
SCRIPTS_DIR="./scripts"
CURRENT_VERSION="0.1.0"

for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] && chmod +x "$script"
done


update_all() {
    echo "🔄 Aktualisiere alle Skripte von GitHub..."

    curl -s -o main.sh "${RAW_URL}/main.sh" && chmod +x main.sh

    [ ! -d "$SCRIPTS_DIR" ] && mkdir -p "$SCRIPTS_DIR"

    ONLINE_SCRIPTS=$(curl -s "https://api.github.com/repos/tenbyte/ncm/contents/scripts" | grep '"name"' | awk -F '"' '{print $4}')

    if [ -z "$ONLINE_SCRIPTS" ]; then
        echo "⚠️ Konnte keine Online-Skripte abrufen!"
        return
    fi

    for script in $ONLINE_SCRIPTS; do
        echo "⬇️  Lade $script herunter..."
        curl -s -o "$SCRIPTS_DIR/$script" "$RAW_URL/scripts/$script"
        chmod +x "$SCRIPTS_DIR/$script"
    done

    echo "✅ Update abgeschlossen! Bitte starte das Skript neu."
    exit 0
}

check_update() {
    echo "🔄 Prüfe auf Updates für das Hauptskript..."
    LATEST_VERSION=$(curl -s "${RAW_URL}/version.txt" | tr -d '\r')

    if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️ Konnte keine Versionsinformationen abrufen!"
        return
    fi

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "🚀 Update verfügbar: $LATEST_VERSION (aktuell: $CURRENT_VERSION)"
        echo "Möchtest du das **ganze Skript-Paket** aktualisieren? (y/n)"
        read -r choice
        if [ "$choice" == "y" ]; then
            update_all
        fi
    else
        echo "✅ Du nutzt die neueste Version ($CURRENT_VERSION)."
    fi

    echo "⚠️ Möchtest du trotzdem ein **Force Update** ausführen? (y/n)"
    read -r force_choice
    if [ "$force_choice" == "y" ]; then
        update_all
    fi
}


run_local_script() {
    scripts=($(ls "$SCRIPTS_DIR"/*.sh 2>/dev/null))
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "⚠️ Keine lokalen Skripte gefunden!"
        return
    fi

    echo "📂 Verfügbare lokale Skripte:"
    for i in "${!scripts[@]}"; do
        echo "$((i+1))) $(basename "${scripts[$i]}")"
    done

    echo "0) Zurück zum Hauptmenü"
    read -p "Wähle ein Skript zum Ausführen: " choice

    if [ "$choice" -eq 0 ]; then
        return
    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#scripts[@]} ]; then
        echo "🔄 Starte $(basename "${scripts[$((choice-1))]}")..."
        bash "${scripts[$((choice-1))]}"
    else
        echo "❌ Ungültige Eingabe!"
    fi
}

list_online_scripts() {
    echo "🌍 Prüfe Online-Skripte & lokale Versionen..."
    
    VERSION_DATA=$(curl -s "$RAW_URL/scripts/version.txt")

    if [ -z "$VERSION_DATA" ]; then
        echo "⚠️ Konnte die Online-Versionsdatei nicht abrufen!"
        return
    fi

    echo -e "📂 Vergleich lokale vs. Online-Skripte:"
    echo "--------------------------------------"

    echo "$VERSION_DATA" | while IFS="=" read -r script version_online; do
        local_script="$SCRIPTS_DIR/$script"

        if [ -f "$local_script" ]; then
            version_local=$(grep -E "^# Version: " "$local_script" | awk '{print $3}')

            if [ -z "$version_local" ]; then
                version_local="Unbekannt"
            fi

            if [ "$version_local" == "$version_online" ]; then
                echo -e "✅ \e[32m$script (Version: $version_local) ist aktuell\e[0m"
            else
                echo -e "🔄 \e[33m$script (Lokal: $version_local, Online: $version_online) - Update verfügbar!\e[0m"
            fi
        else
            echo -e "❌ \e[31m$script fehlt lokal! (Online: $version_online)\e[0m"
        fi
    done
}


show_menu() {
    clear
    echo "==============================="
    echo " NCM by Tenbyte v$CURRENT_VERSION"
    echo "==============================="
    echo "1) Update prüfen & alle Skripte aktualisieren"
    echo "2) Lokale Skripte anzeigen & ausführen"
    echo "3) Online verfügbare Skripte prüfen"
    echo "4) Beenden"
    echo "==============================="
    read -p "Wähle eine Option: " choice

    case $choice in
        1) check_update ;;
        2) run_local_script ;;
        3) list_online_scripts ;;
        4) exit 0 ;;
        *) echo "Ungültige Eingabe!" ;;
    esac
}


while true; do
    show_menu
    read -p "Drücke Enter zum Fortfahren..." 
done
