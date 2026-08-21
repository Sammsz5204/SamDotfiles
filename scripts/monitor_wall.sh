#!/bin/bash

# Caminho absoluto pro inotifywait achar
ARQUIVO_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Pega a pasta onde esse monitor tá salvo
DIR_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "Escutando mudanças no wallpaper, twin..."

# O loop infinito continua, mas agora ele ignora eventos duplicados do editor
while true; do
    inotifywait -q -e close_write "$ARQUIVO_CONF"
    echo "Wallpaper atualizado! Rodando o sync..."
    
    # Chama o gerador usando o caminho completo
    "$DIR_SCRIPTS/gerar_tema.sh"
    
    # Espera 1 segundo pra não enlouquecer com os 3 eventos que o editor manda
    sleep 1
done
