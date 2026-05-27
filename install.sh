#!/usr/bin/env bash
# Crea symlinks de ~/dotfiles/config/* hacia ~/.config/*
# Backupea cualquier archivo existente como *.bak-<timestamp> antes de pisar.

set -euo pipefail
cd "$(dirname "$0")"
REPO_ROOT="$PWD"
SRC="$REPO_ROOT/config"
DST="$HOME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { printf "${GREEN}✔  %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠  %s${NC}\n" "$*"; }
info() { printf "${BLUE}ℹ  %s${NC}\n" "$*"; }
err()  { printf "${RED}✘  %s${NC}\n" "$*"; }

# Flag: --no-packages para saltar la instalación de paquetes (más rápido al re-ejecutar)
SKIP_PACKAGES=0
for arg in "$@"; do
    case "$arg" in
        --no-packages|-n) SKIP_PACKAGES=1 ;;
    esac
done

mkdir -p "$DST"

# Carpetas que NO van a ~/.config (se manejan en bloques especiales abajo)
declare -A SPECIAL_DIRS=( [zsh-custom]=1 [systemd]=1 )

# === Carpetas: linkear archivo por archivo ===
for dir in "$SRC"/*/; do
    name=$(basename "$dir")
    [[ -n "${SPECIAL_DIRS[$name]:-}" ]] && continue
    target="$DST/$name"

    # Si ya es directorio con todos los archivos symlinkeados a este repo, saltar
    if [[ -d "$target" && ! -L "$target" ]]; then
        all_linked=1
        for f in "$dir"*; do
            fn=$(basename "$f")
            [[ -L "$target/$fn" && "$(readlink "$target/$fn")" == "$f" ]] || all_linked=0
        done
        if [[ $all_linked -eq 1 ]]; then
            ok "$target ya tiene todo linkeado"
            continue
        fi
    fi

    mkdir -p "$target"
    for file in "$dir"*; do
        fname=$(basename "$file")
        link="$target/$fname"
        if [[ -e "$link" && ! -L "$link" ]]; then
            mv "$link" "$link.bak-$(date +%s)"
        fi
        ln -sfn "$file" "$link"
        ok "linked $link"
    done
done

# === Archivos sueltos en config/ ===
shopt -s nullglob
for file in "$SRC"/*; do
    [[ -d "$file" ]] && continue
    fname=$(basename "$file")
    link="$DST/$fname"
    if [[ -e "$link" && ! -L "$link" ]]; then
        warn "$link existe — moviendo a $link.bak-$(date +%s)"
        mv "$link" "$link.bak-$(date +%s)"
    fi
    ln -sf "$file" "$link"
    ok "linked $link"
done

# === Casos especiales: snippets que NO van a ~/.config ===
ZSH_CUSTOM_SRC="$SRC/zsh-custom"
if [[ -d "$ZSH_CUSTOM_SRC" && -d "$HOME/.oh-my-zsh/custom" ]]; then
    for f in "$ZSH_CUSTOM_SRC"/*.zsh; do
        [[ -e "$f" ]] || continue
        fname=$(basename "$f")
        link="$HOME/.oh-my-zsh/custom/$fname"
        [[ -e "$link" && ! -L "$link" ]] && mv "$link" "$link.bak-$(date +%s)"
        ln -sf "$f" "$link"
        ok "linked $link"
    done
fi

# === Linkear zshrc (para entornos sin Nix) ===
ZSHRC_SRC="$REPO_ROOT/zshrc"
if [[ -f "$ZSHRC_SRC" ]]; then
    ZSHRC_DST="$HOME/.zshrc"
    if [[ -e "$ZSHRC_DST" && ! -L "$ZSHRC_DST" ]]; then
        warn "$ZSHRC_DST existe — moviendo a $ZSHRC_DST.bak-$(date +%s)"
        mv "$ZSHRC_DST" "$ZSHRC_DST.bak-$(date +%s)"
    fi
    ln -sf "$ZSHRC_SRC" "$ZSHRC_DST"
    ok "linked $ZSHRC_DST"
fi


# === systemd user units (preserva subdirs como *.service.d/override.conf) ===
SYSTEMD_SRC="$SRC/systemd"
SYSTEMD_DST="$DST/systemd"
if [[ -d "$SYSTEMD_SRC" ]]; then
    while IFS= read -r -d '' file; do
        rel="${file#"$SYSTEMD_SRC"/}"
        link="$SYSTEMD_DST/$rel"
        mkdir -p "$(dirname "$link")"
        if [[ -e "$link" && ! -L "$link" ]]; then
            mv "$link" "$link.bak-$(date +%s)"
        fi
        ln -sfn "$file" "$link"
        ok "linked $link"
    done < <(find "$SYSTEMD_SRC" -type f -print0)
    # Recargar systemd para que reconozca units/overrides nuevos
    systemctl --user daemon-reload 2>/dev/null || true
fi

# === bin/ → ~/.local/bin/ (scripts ejecutables) ===
BIN_SRC="$REPO_ROOT/bin"
BIN_DST="$HOME/.local/bin"
if [[ -d "$BIN_SRC" ]]; then
    mkdir -p "$BIN_DST"
    for file in "$BIN_SRC"/*; do
        [[ -f "$file" && -x "$file" ]] || continue
        fname=$(basename "$file")
        link="$BIN_DST/$fname"
        if [[ -e "$link" && ! -L "$link" ]]; then
            mv "$link" "$link.bak-$(date +%s)"
        fi
        ln -sfn "$file" "$link"
        ok "linked $link"
    done
fi

# === Paquetes (pacman + AUR helper) ===
#
# Instala lo necesario para que el pipeline funcione end-to-end:
#   - File picker: yazi + previews (ffmpeg, poppler, ffmpegthumbnailer, librsvg)
#   - Portal File Picker: xdg-desktop-portal-termfilechooser (AUR)
#   - Bridge matugen → Qt: kde-material-you-colors (AUR)
#
# Para saltar esta fase: ./install.sh --no-packages
if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
    info "Saltando install de paquetes (--no-packages)"
elif ! command -v pacman >/dev/null; then
    warn "pacman no encontrado — esta distro no es Arch-like. Saltando paquetes."
else
    PACMAN_PKGS=(yazi ffmpeg poppler ffmpegthumbnailer librsvg)
    AUR_PKGS=(xdg-desktop-portal-termfilechooser kde-material-you-colors)

    # Filtrar a los que NO están instalados
    missing_pacman=()
    for p in "${PACMAN_PKGS[@]}"; do
        pacman -Qi "$p" >/dev/null 2>&1 || missing_pacman+=("$p")
    done
    missing_aur=()
    for p in "${AUR_PKGS[@]}"; do
        pacman -Qi "$p" >/dev/null 2>&1 || missing_aur+=("$p")
    done

    if (( ${#missing_pacman[@]} == 0 && ${#missing_aur[@]} == 0 )); then
        ok "Todos los paquetes ya están instalados"
    else
        echo
        info "Paquetes a instalar:"
        (( ${#missing_pacman[@]} )) && echo "    pacman: ${missing_pacman[*]}"
        (( ${#missing_aur[@]} ))    && echo "    AUR:    ${missing_aur[*]}"
        echo

        # Detectar AUR helper si hace falta
        AUR_HELPER=""
        if (( ${#missing_aur[@]} > 0 )); then
            for h in paru yay; do
                if command -v "$h" >/dev/null; then AUR_HELPER="$h"; break; fi
            done
            if [[ -z "$AUR_HELPER" ]]; then
                err "Necesito un AUR helper (paru o yay) para instalar: ${missing_aur[*]}"
                err "Instalá uno primero: https://github.com/Morganamilo/paru"
                exit 1
            fi
            info "Usando AUR helper: $AUR_HELPER"
        fi

        # Instalar repos oficiales
        if (( ${#missing_pacman[@]} > 0 )); then
            info "Instalando con pacman (te va a pedir password)..."
            sudo pacman -S --needed --noconfirm "${missing_pacman[@]}"
            ok "pacman: instalados ${missing_pacman[*]}"
        fi

        # Instalar AUR
        if (( ${#missing_aur[@]} > 0 )); then
            info "Instalando con $AUR_HELPER..."
            "$AUR_HELPER" -S --needed --noconfirm "${missing_aur[@]}"
            ok "AUR: instalados ${missing_aur[*]}"
        fi
    fi
fi

# === Bootstrap matugen ===
# fuzzel.ini, kitty.conf y hyprland.conf hacen include/source de archivos que
# genera matugen (fuzzel_theme.ini, kitty/colors.conf, hypr/colors.conf, ...).
# En un clone fresco no existen hasta el primer `wall`, así que los generamos ya
# con un color por defecto para que nada falte en el primer arranque.
if command -v matugen >/dev/null; then
    if [[ ! -f "$HOME/.config/hypr/colors.conf" ]]; then
        info "Generando temas iniciales con matugen (color por defecto)..."
        if matugen color hex "#6750a4" --mode dark >/dev/null 2>&1; then
            ok "Temas matugen generados — cambialos cuando quieras con: wall <imagen>"
        else
            warn "matugen falló — corré 'wall <imagen>' a mano para generar los temas."
        fi
    fi
else
    warn "matugen no instalado: corré install-ambxst.sh primero, después 'wall <imagen>'."
fi

echo
ok "Listo. Editá ~/.config/* normalmente — son symlinks a este repo."
echo
warn "Asegurate de tener ~/.local/bin en tu PATH para los scripts de bin/."
