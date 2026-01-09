#!/bin/bash

# ===== CONFIG =====
TRIGGER=";;"
BUFFER=""
MAX_BUFFER=50

KEYBOARD_ID=$(xinput list | grep -i "keyboard" | head -n1 | sed 's/.*id=\([0-9]*\).*/\1/')

notify() {
    notify-send "🤖 SecretBot" "$1" -t 1500
}

focus_mode() {
    notify "Modo foco ativado"
    pactl set-sink-mute @DEFAULT_SINK@ 1
}

panic_mode() {
    notify "PANIC MODE 😱"
    wmctrl -k on
    pactl set-sink-mute @DEFAULT_SINK@ 1
}

sleep_mode() {
    notify "Hora de dormir 😴"
    gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true
    brightnessctl set 30%
}

rick_mode() {
    notify "🎵 Never gonna give you up..."
    mpv --no-video --volume=80 "https://archive.org/download/rick-astley-never-gonna-give-you-up/Rick%20Astley%20-%20Never%20Gonna%20Give%20You%20Up.mp3" >/dev/null 2>&1 &
}

handle_command() {
    case "$1" in
        focus)
            focus_mode
            ;;
        panic)
            panic_mode
            ;;
        sleep)
            sleep_mode
            ;;
        rick)
            rick_mode
            ;;
        *)
            notify "Comando desconhecido: $1"
            ;;
    esac
}

# ===== LISTENER =====
xinput test "$KEYBOARD_ID" | while read -r line; do
    if [[ $line == *"key press"* ]]; then
        KEY=$(echo "$line" | awk '{print $NF}')

        CHAR=$(xdotool key --keycode "$KEY" 2>/dev/null)

        BUFFER+="$CHAR"
        BUFFER="${BUFFER: -$MAX_BUFFER}"

        if [[ "$BUFFER" == *"$TRIGGER"* ]]; then
            CMD="${BUFFER##*$TRIGGER}"
            CMD="${CMD%% *}"

            handle_command "$CMD"
            BUFFER=""
        fi
    fi
done
