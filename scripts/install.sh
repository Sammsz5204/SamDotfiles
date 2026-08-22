#!/usr/bin/env bash

set -e

# ── Cores ─────────────────────────────────────────────
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

# ── Diretórios base ────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${HOME}/.config"
FONTS_DIR="${HOME}/.local/share/fonts"
BACKUP_DIR="${HOME}/.config-backup/$(date +%Y%m%d_%H%M%S)"
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"

# ── Pacotes necessários (Arch / pacman) ─────────────────
PACKAGES=(
    # Desktop Environment & Compositor
    hyprland
    hyprlock
    hyprpaper
    swaync
    cava
    kitty
    ghostty

    # Suporte a Temas e Scripts (LUA / ImageMagick / Python)
    imagemagick
    lua
    lua-lgi
    lua51
    lua51-lgi
    python
    python-pip

    # Apps & Utilitários de Sistema
    nautilus
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    btop
    neovim
    papirus-icon-theme
    nwg-look
    playerctl
    grim
    slurp
    firefox
    discord
    flatpak
    mpd
    rmpc
    mpc

    # Build & Fontes
    base-devel
    git
    unzip
    ttf-font-awesome
    ttf-jetbrains-mono-nerd
    cowsay
    sl
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
        # Não aborta o install inteiro por causa de uma pasta opcional
        # que ainda não existe no repo (ex: ghostty/, nvim/) — só avisa
        # e segue pras outras.
        warn "Pulando (fonte não encontrada ainda): $src"
        return 0
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
        warn "Instale manualmente os pacotes necessários."
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

    # Copia as fontes do repo (SF Pro, StretchPro, Suisse), exceto JetBrains
    if [[ -d "$fonts_src" ]]; then
        find "$fonts_src" -type f \( -name "*.ttf" -o -name "*.otf" \) \
            ! -iname "*jetbrains*" | while read -r font; do
            local fname
            fname=$(basename "$font")
            cp -f "$font" "$FONTS_DIR/$fname"
            success "Font: $fname"
        done
    else
        warn "Pasta de fontes não encontrada em $fonts_src"
    fi

    # Baixa JetBrainsMono Nerd Font v3 atualizada direto do GitHub
    info "Baixando JetBrainsMono Nerd Font v3..."
    local tmp_zip
    tmp_zip="$(mktemp /tmp/JetBrainsMonoNerd.XXXXXX.zip)"

    if curl -fsSL --progress-bar \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
        -o "$tmp_zip"; then
        unzip -o -q "$tmp_zip" -d "$FONTS_DIR"
        rm -f "$tmp_zip"
        success "JetBrainsMono Nerd Font v3 instalada."
    else
        error "Falha ao baixar JetBrainsMono — verifique sua conexão."
        warn "Usando a versão do repo como fallback."
        find "$fonts_src" -type f -iname "*jetbrains*" | while read -r font; do
            cp -f "$font" "$FONTS_DIR/$(basename "$font")"
        done
    fi

    # Atualiza cache de fontes
    if command -v fc-cache &>/dev/null; then
        fc-cache -fv "$FONTS_DIR" &>/dev/null
        success "Cache de fontes atualizado."
    fi
}

make_scripts_executable() {
    header "Tornando scripts executáveis (.sh, .lua, .py)"
    find "$DOTFILES_DIR" -type f \( -name "*.sh" -o -name "*.lua" -o -name "*.py" \) | while read -r script; do
        chmod +x "$script"
        success "chmod +x: $(basename "$script")"
    done
}

link_dotfiles() {
    header "Linkando dotfiles"

    # Mapeamento: pasta_no_repo → destino_em_~/.config
    declare -A CONFIGS=(
        ["${DOTFILES_DIR}/btop"]="${CONFIG_DIR}/btop"
        ["${DOTFILES_DIR}/ghostty"]="${CONFIG_DIR}/ghostty"
        ["${DOTFILES_DIR}/hypr"]="${CONFIG_DIR}/hypr"
        ["${DOTFILES_DIR}/kitty"]="${CONFIG_DIR}/kitty"
        ["${DOTFILES_DIR}/nvim"]="${CONFIG_DIR}/nvim"
        ["${DOTFILES_DIR}/nwg-look"]="${CONFIG_DIR}/nwg-look"
        ["${DOTFILES_DIR}/quickshell"]="${CONFIG_DIR}/quickshell"
        ["${DOTFILES_DIR}/scripts"]="${CONFIG_DIR}/scripts"
    )

    for src in "${!CONFIGS[@]}"; do
        link_config "$src" "${CONFIGS[$src]}"
    done
}

setup_wallpapers_and_theme() {
    header "Configuração de Wallpapers & Tema Inicial"
    mkdir -p "$WALLPAPER_DIR"
    info "Diretório de wallpapers criado/verificado em: $WALLPAPER_DIR"

    # Tenta rodar o gerador de temas para criar os arquivos de cores pela primeira vez
    # (gerar_tema.sh mora em scripts/, que e' linkado pra ~/.config/scripts)
    if [[ -f "${CONFIG_DIR}/scripts/gerar_tema.sh" ]]; then
        info "Inicializando geração da paleta de cores..."
        bash "${CONFIG_DIR}/scripts/gerar_tema.sh" || warn "Adicione pelo menos uma imagem em $WALLPAPER_DIR para o tema ser gerado automaticamente."
    fi
}

# ═══════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════

echo -e "${BOLD}"
cat <<'EOF'
  ____        _   _   _ ____  _ _      
 / ___|  __ _| |_| |_| |  _ \(_) | ___ ___ 
 \___ \ / _` | __| __| | |_) | | |/ _ / __|
  ___) | (_| | |_| |_| |  _ <| | |  __\__ \
 |____/ \__,_|\__|\__|_|_| \_\_|_|\___|___/

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
setup_wallpapers_and_theme

echo ""
success "Tudo pronto! Coloque seus wallpapers em ~/Pictures/Wallpapers e reinicie a sessão do Hyprland. 🎉"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    info "Backups das configs antigas salvos em: $BACKUP_DIR"
fi
