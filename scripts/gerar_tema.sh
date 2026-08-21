#!/bin/bash

# Caminho absoluto pro arquivo de configuracao do hyprpaper
ARQUIVO_CONF="$HOME/.config/hypr/hyprpaper.conf"
SAIDA_HYPR="$HOME/.config/hypr/colors.lua"
SAIDA_EWW="$HOME/.config/eww/colors.scss"
SAIDA_LOCK="$HOME/.config/hypr/colors.conf"

# CAMINHO DE OUTROS APPS
SAIDA_KITTY="$HOME/.config/kitty/colors.conf"
SAIDA_ROFI="$HOME/.config/rofi/colors.rasi"
SAIDA_QUICKSHELL="$HOME/.config/quickshell/Colors.qml"
mkdir -p "$(dirname "$SAIDA_QUICKSHELL")"

rm -f "$HOME/.config/quickshell/qmldir"

# Diretório onde este script está salvo
DIR_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ ! -f "$ARQUIVO_CONF" ]; then
    echo "Arquivo de config não encontrado em: $ARQUIVO_CONF"
    exit 1
fi

CAMINHO_BRUTO=$(grep -oE '[/~][^ '\''" "]+\.(jpg|jpeg|png|webp|gif)' "$ARQUIVO_CONF" | head -n 1)
CAMINHO_WALLPAPER="${CAMINHO_BRUTO/#\~/$HOME}"

if [ -z "$CAMINHO_WALLPAPER" ] || [ ! -f "$CAMINHO_WALLPAPER" ]; then
    echo "Não achei a imagem no hyprpaper.conf ou o arquivo não existe: '$CAMINHO_WALLPAPER'"
    exit 1
fi

echo "Wallpaper identificado: $CAMINHO_WALLPAPER"

# Executa o Lua passando a imagem e os 6 destinos (sem Waybar)
if lua "$DIR_SCRIPTS/extrair_cores.lua" "$CAMINHO_WALLPAPER" "$SAIDA_HYPR" "$SAIDA_EWW" "$SAIDA_LOCK" "$SAIDA_KITTY" "$SAIDA_ROFI" "$SAIDA_QUICKSHELL"; then
    hyprctl reload
    
    # Recarrega as cores do Kitty
    if pgrep -x kitty > /dev/null; then
        kitty @ set-colors -a -c "$SAIDA_KITTY" &>/dev/null
    fi

    echo "Cores sincronizadas com sucesso, twin!"
else
    echo "Erro ao executar o script Lua."
fi
