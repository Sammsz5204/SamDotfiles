#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║         Sammsz dotfiles — install.sh                 ║
# ║  Hyprland · Waybar · Ghostty · Nvim · Rofi · Cava   ║
# ╚══════════════════════════════════════════════════════╝

set -e

# ── Cores ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[•]${NC} $*"; }
success() { echo -e "${GREEN}${BOLD}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${NC} $*"; }
error()   { echo -e "${RED}${BOLD}[✗]${NC} $*" >&2; }
header()  { echo -e "\n${BLUE}${BOLD}── $* ──────────────────────────────${NC}"; }

# ── Diretório base (onde o install.sh está) ─────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config"
FONTS_DIR="${HOME}/.local/share/fonts"
BACKUP_DIR="${HOME}/.config-backup/$(date +%Y%m%d_%H%M%S)"

# ── Pacotes necessários (Arch / pacman) ─────────────────
PACKAGES=(
    hyprland
    hyprlock
    hyprpaper
    mpvpaper
    waybar
    rofi-wayland
    cava
    ghostty
    neovim
    dunst
    playerctl
    bluez
    bluez-utils
    networkmanager
    git
    unzip
    ttf-font-awesome
)

# ═══════════════════════════════════════════════════════
#  FUNÇÕES
# ═══════════════════════════════════════════════════════

backup_config() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        local name
        name=$(basename "$target")
        warn "Backup de $target → $BACKUP_DIR/$name"
        mv "$target" "$BACKUP_DIR/$name"
    fi
}

link_config() {
    local src="$1"   # caminho dentro do repo
    local dest="$2"  # destino em ~/.config

    if [[ ! -e "$src" ]]; then
        error "Fonte não encontrada: $src"
        return 1
    fi

    backup_config "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "Linked: $(basename "$dest")"
}

install_packages() {
    header "Instalando pacotes"

    if ! command -v pacman &>/dev/null; then
        warn "pacman não encontrado — pulando instalação de pacotes."
        warn "Instale manualmente: ${PACKAGES[*]}"
        return
    fi

    local missing=()
    for pkg in "${PACKAGES[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "Todos os pacotes já estão instalados."
        return
    fi

    info "Pacotes a instalar: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}" && success "Pacotes instalados."
}

install_fonts() {
    header "Instalando fontes"
    mkdir -p "$FONTS_DIR"

    local fonts_src="${DOTFILES_DIR}/hypr/Fonts"

    if [[ ! -d "$fonts_src" ]]; then
        warn "Pasta de fontes não encontrada em $fonts_src"
        return
    fi

    # Copia todas as fontes recursivamente
    find "$fonts_src" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r font; do
        local fname
        fname=$(basename "$font")
        cp -f "$font" "$FONTS_DIR/$fname"
        success "Font: $fname"
    done

    # Atualiza cache de fontes
    if command -v fc-cache &>/dev/null; then
        fc-cache -fv "$FONTS_DIR" &>/dev/null
        success "Cache de fontes atualizado."
    fi
}

make_scripts_executable() {
    header "Tornando scripts executáveis"
    find "$DOTFILES_DIR" -name "*.sh" | while read -r script; do
        chmod +x "$script"
        success "chmod +x: $(basename "$script")"
    done
}

link_dotfiles() {
    header "Linkando dotfiles"

    # Mapeamento: pasta_no_repo → destino_em_~/.config
    declare -A CONFIGS=(
        ["${DOTFILES_DIR}/cava"]="${CONFIG_DIR}/cava"
        ["${DOTFILES_DIR}/ghostty"]="${CONFIG_DIR}/ghostty"
        ["${DOTFILES_DIR}/hypr"]="${CONFIG_DIR}/hypr"
        ["${DOTFILES_DIR}/nvim"]="${CONFIG_DIR}/nvim"
        ["${DOTFILES_DIR}/rofi"]="${CONFIG_DIR}/rofi"
        ["${DOTFILES_DIR}/waybar"]="${CONFIG_DIR}/waybar"
    )

    for src in "${!CONFIGS[@]}"; do
        link_config "$src" "${CONFIGS[$src]}"
    done
}

wallpaper_reminder() {
    header "Wallpaper"
    warn "O hyprland.conf aponta para: /home/sam/.Wallpapers/miku.mp4"
    info "Crie a pasta e coloque seu wallpaper lá, ou edite o caminho em:"
    echo "     ${CONFIG_DIR}/hypr/hyprland.conf"
    echo "     Linha: exec-once = mpvpaper ..."
}

# ═══════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════

echo -e "${BOLD}"
cat <<'EOF'
  ____                                     _       _    __ _ _
 / ___|  __ _ _ __ ___  _ __ ___  ___ ___| |_ ___| |_ / _(_) | ___ ___
 \___ \ / _` | '_ ` _ \| '_ ` _ \/ __/ __| __/ __| __| |_| | |/ _ / __|
  ___) | (_| | | | | | | | | | | \__ \__ | |_\__ | |_|  _| | |  __\__ \
 |____/ \__,_|_| |_| |_|_| |_| |_|___/___/\__|___/\__|_| |_|_|\___|___/

                     dotfiles installer by Sammsz
EOF
echo -e "${NC}"

# Flags
SKIP_PACKAGES=false
SKIP_FONTS=false

for arg in "$@"; do
    case $arg in
        --skip-packages) SKIP_PACKAGES=true ;;
        --skip-fonts)    SKIP_FONTS=true ;;
        --help|-h)
            echo "Uso: ./install.sh [opções]"
            echo ""
            echo "  --skip-packages   Não instala pacotes via pacman"
            echo "  --skip-fonts      Não instala fontes"
            exit 0
            ;;
    esac
done

$SKIP_PACKAGES || install_packages
$SKIP_FONTS    || install_fonts

make_scripts_executable
link_dotfiles
wallpaper_reminder

echo ""
success "Tudo pronto! Reinicie o Hyprland pra aplicar as configs. 🎉"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    info "Backups salvos em: $BACKUP_DIR"
fi
