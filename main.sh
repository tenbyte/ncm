#!/bin/bash

# === KONFIGURATION ===
REPO_URL="https://github.com/tenbyte/ncm"
RAW_URL="https://raw.githubusercontent.com/tenbyte/ncm/main"
SCRIPTS_DIR="./scripts"
CURRENT_VERSION="0.1.0"

for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] && chmod +x "$script"
done


# === FUNKTION: UPDATE CHECKER ===
check_update() {
    echo "🔄 Prüfe auf Updates für das Hauptskript..."
    LATEST_VERSION=$(curl -s "${RAW_URL}/version.txt" | tr -d '\r')

    if [ -z "$LATEST_VERSION" ]; then
        echo "⚠️ Konnte keine Versionsinformationen abrufen!"
        return
    fi

    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
        echo "🚀 Update verfügbar: $LATEST_VERSION (aktuell: $CURRENT_VERSION)"
        echo "Möchtest du das Update jetzt ausführen? (y/n)"
        read -r choice
        if [ "$choice" == "y" ]; then
            echo "🔄 Lade Update herunter..."
            curl -s -o main.sh "${RAW_URL}/main.sh"
            chmod +x main.sh
            echo "✅ Update abgeschlossen! Bitte starte das Skript neu."
            exit 0
        else
            echo "⚠️ Update abgelehnt. Du nutzt Version $CURRENT_VERSION."
        fi
    else
        echo "✅ Du nutzt die neueste Version ($CURRENT_VERSION)."
    fi
}

# === FUNKTION: LOKALE SCRIPTE LISTEN & AUSFÜHREN ===
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


# === FUNKTION: ONLINE-SKRIPTE ABRUFEN ===
list_online_scripts() {
    echo "🌍 Verfügbare Online-Skripte:"
    ONLINE_SCRIPTS=$(curl -s "https://api.github.com/repos/tenbyte/ncm/contents/scripts" | grep '"name"' | awk -F '"' '{print "  - " $4}')
    if [ -z "$ONLINE_SCRIPTS" ]; then
        echo "⚠️ Konnte keine Online-Skripte abrufen!"
    else
        echo "$ONLINE_SCRIPTS"
    fi
}

# === FUNKTION: MENÜ ===
show_menu() {
    clear
    echo "==============================="
    echo " NCM by Tenbyte v$CURRENT_VERSION"
    echo "==============================="
    echo "1) Update prüfen"
    echo "2) Lokale Skripte anzeigen"
    echo "3) Online verfügbare Skripte anzeigen"
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

# === START: MENÜ-SCHLEIFE ===
while true; do
    show_menu
    read -p "Drücke Enter zum Fortfahren..." 
done
