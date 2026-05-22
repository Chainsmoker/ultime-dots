#!/usr/bin/env bash
# Editable Ambxst installer for Arch Linux.
#
# Differences vs the upstream installer (https://github.com/Axenide/Ambxst/blob/main/install.sh):
#   - Clones to ~/Repos/Ambxst (override with $AMBXST_INSTALL_DIR).
#   - NEVER does `git reset --hard` — your edits are preserved.
#   - Adds an `upstream` remote so you can `git fetch upstream` / `git rebase upstream/main`
#     conventionally without losing changes.
#   - Installs a USER launcher at ~/.local/bin/ambxst (no sudo to edit/replace).
#   - Quickshell hot-reloads QML on save, so once running you can edit .qml files
#     in the clone directly and see changes live — no reinstall needed.
#
# Usage:
#   bash install-ambxst.sh                    # solo Ambxst (asume Hyprland ya instalado)
#   bash install-ambxst.sh --with-hyprland    # también instala Hyprland + portales
#
# Optional env overrides:
#   AMBXST_REPO_URL=https://github.com/<you>/Ambxst.git   # your fork
#   AMBXST_INSTALL_DIR=$HOME/Code/Ambxst
#   AMBXST_LAUNCHER_DIR=$HOME/.local/bin
#   AMBXST_BRANCH=main

set -euo pipefail

# === Flags ===
WITH_HYPRLAND=0
for arg in "$@"; do
    case "$arg" in
        --with-hyprland) WITH_HYPRLAND=1 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Argumento desconocido: $arg" >&2; exit 1 ;;
    esac
done

# === Config ===
# Por defecto: tu fork con los parches (UX del notch, click workspaces, etc.).
# Para upstream limpio: AMBXST_REPO_URL=https://github.com/Axenide/Ambxst.git AMBXST_BRANCH=main
REPO_URL="${AMBXST_REPO_URL:-https://github.com/Chainsmoker/Ambxst.git}"
UPSTREAM_URL="https://github.com/Axenide/Ambxst.git"
INSTALL_DIR="${AMBXST_INSTALL_DIR:-$HOME/Repos/Ambxst}"
LAUNCHER_DIR="${AMBXST_LAUNCHER_DIR:-$HOME/.local/bin}"
BRANCH="${AMBXST_BRANCH:-feat/always-show-player}"

# === Helpers ===
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${BLUE}ℹ  %s${NC}\n" "$*" >&2; }
ok()   { printf "${GREEN}✔  %s${NC}\n" "$*" >&2; }
warn() { printf "${YELLOW}⚠  %s${NC}\n" "$*" >&2; }
die()  { printf "${RED}✖  %s${NC}\n" "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

[[ $EUID -eq 0 ]] && die "No corras como root. El script usa sudo cuando hace falta."
has pacman || die "Este instalador es para Arch (pacman no encontrado)."

# === 1. Tools base ===
if ! has git || ! has makepkg; then
    info "Instalando git + base-devel..."
    sudo pacman -S --needed --noconfirm git base-devel
fi

# === 2. AUR helper ===
AUR=""
if   has yay;  then AUR=yay
elif has paru; then AUR=paru
else
    info "Instalando yay-bin desde AUR..."
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp"
    (cd "$tmp" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    AUR=yay
fi
ok "AUR helper: $AUR"

# === 3. Clone / sync (sin pisar tus ediciones) ===
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "$INSTALL_DIR ya existe. Verificando estado..."
    if [[ -n "$(git -C "$INSTALL_DIR" status --porcelain)" ]]; then
        warn "Hay cambios locales — los dejo como están."
        warn "Para sincronizar después: cd $INSTALL_DIR && git fetch upstream && git rebase upstream/$BRANCH"
    else
        info "Limpio. Intentando fast-forward desde origin/$BRANCH..."
        git -C "$INSTALL_DIR" fetch origin
        git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" \
            || warn "La rama divergió. No toco nada — resolvelo a mano."
    fi
elif [[ -e "$INSTALL_DIR" ]]; then
    die "$INSTALL_DIR existe y no es un repo git. Movelo aparte primero."
else
    info "Clonando a $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Agregar remote upstream para poder fetchear sin pisar tu origin (fork)
if ! git -C "$INSTALL_DIR" remote get-url upstream >/dev/null 2>&1; then
    if [[ "$REPO_URL" != "$UPSTREAM_URL" ]]; then
        git -C "$INSTALL_DIR" remote add upstream "$UPSTREAM_URL"
        info "Remote 'upstream' agregado → $UPSTREAM_URL"
    fi
fi

# === 4. Dependencias ===
info "Instalando dependencias con $AUR (--needed, salteo lo ya instalado)..."
PKGS=(
    # Quickshell + Qt
    quickshell qt6-base qt6-declarative qt6-wayland qt6-svg qt6-tools
    qt6-imageformats qt6-multimedia qt6-shadertools libwebp libavif
    syntax-highlighting breeze-icons hicolor-icon-theme
    # Apps / utils
    kitty tmux fuzzel network-manager-applet blueman
    pipewire wireplumber pavucontrol easyeffects ffmpeg x264 playerctl
    brightnessctl ddcutil fontconfig grim slurp imagemagick jq sqlite upower
    wl-clipboard wlsunset wtype zbar glib2 python-pipx zenity inetutils
    power-profiles-daemon python312 libnotify
    # OCR
    tesseract tesseract-data-eng tesseract-data-spa tesseract-data-jpn
    tesseract-data-chi_sim tesseract-data-chi_tra tesseract-data-kor tesseract-data-lat
    # Fuentes
    ttf-roboto ttf-roboto-mono ttf-dejavu ttf-liberation
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-nerd-fonts-symbols
    ttf-phosphor-icons ttf-league-gothic
    # Themes + extras
    adw-gtk-theme matugen gpu-screen-recorder wl-clip-persist mpvpaper gradia
    # Go: para compilar axctl desde el fork con el fix de Hyprland 0.55+
    go
    # Icons + folder color dinámico (apply-folder-color)
    papirus-icon-theme papirus-folders-git
)
$AUR -S --needed --noconfirm "${PKGS[@]}"

# === 4b. Hyprland (opcional, con --with-hyprland) ===
if [[ $WITH_HYPRLAND -eq 1 ]]; then
    info "Instalando Hyprland + ecosistema (portales, polkit)..."
    HYPR_PKGS=(
        hyprland
        xdg-desktop-portal-hyprland   # screen share, file pickers
        xdg-desktop-portal-gtk        # fallback portal (file pickers GTK)
        polkit-kde-agent              # diálogos de autenticación gráficos
        qt5-wayland qt6-wayland       # apps Qt en Wayland
        xorg-xwayland                 # apps X11 dentro de Hyprland
        hyprpolkitagent               # alternativa de polkit (opcional)
    )
    $AUR -S --needed --noconfirm "${HYPR_PKGS[@]}" || warn "Algún paquete de Hyprland falló — revisá arriba."
    ok "Hyprland instalado. Reiniciá tu display manager (sddm/gdm/lightdm) para que aparezca en el selector de sesión."
else
    if ! has Hyprland && ! has hyprland; then
        warn "Hyprland NO está instalado. Volvé a correr con --with-hyprland, o instalalo a mano:"
        warn "    $AUR -S hyprland xdg-desktop-portal-hyprland polkit-kde-agent"
    fi
fi

# === 5. axctl — construir desde el fork con fix de Hyprland 0.55+ ===
# Upstream tiene un bug (Axenide/axctl#3): SwitchWorkspace y ToggleSpecialWorkspace
# usan sintaxis Lua que Hyprland mainline rechaza. La branch en el fork lo arregla.
AXCTL_REPO_URL="${AXCTL_REPO_URL:-https://github.com/Chainsmoker/axctl.git}"
AXCTL_BRANCH="${AXCTL_BRANCH:-fix/hyprland-dispatcher}"
AXCTL_INSTALL_DIR="${AXCTL_INSTALL_DIR:-$HOME/Repos/axctl}"

info "Instalando axctl desde $AXCTL_REPO_URL ($AXCTL_BRANCH)..."
if [[ -d "$AXCTL_INSTALL_DIR/.git" ]]; then
    info "axctl ya clonado en $AXCTL_INSTALL_DIR, actualizando..."
    git -C "$AXCTL_INSTALL_DIR" fetch origin "$AXCTL_BRANCH"
    git -C "$AXCTL_INSTALL_DIR" checkout "$AXCTL_BRANCH"
    git -C "$AXCTL_INSTALL_DIR" pull --ff-only origin "$AXCTL_BRANCH" || warn "No pude FF, dejo como está."
else
    mkdir -p "$(dirname "$AXCTL_INSTALL_DIR")"
    git clone -b "$AXCTL_BRANCH" "$AXCTL_REPO_URL" "$AXCTL_INSTALL_DIR"
fi

info "Compilando axctl..."
(cd "$AXCTL_INSTALL_DIR" && go build -o bin/axctl .)

info "Instalando binary en /usr/local/bin/axctl (sudo)..."
sudo install -m 0755 "$AXCTL_INSTALL_DIR/bin/axctl" /usr/local/bin/axctl

ok "axctl instalado: $(axctl --help 2>&1 | head -1 || true)"

# === 6. Launcher de usuario ===
mkdir -p "$LAUNCHER_DIR"
LAUNCHER="$LAUNCHER_DIR/ambxst"
info "Escribiendo launcher: $LAUNCHER"
cat >"$LAUNCHER" <<EOF
#!/usr/bin/env bash
# Launcher de usuario — apunta a $INSTALL_DIR.
# Editá los .qml ahí dentro libremente; Quickshell hace hot-reload.
export PATH="\$HOME/.local/bin:\$PATH"
export QML2_IMPORT_PATH="\$HOME/.local/lib/qml:\${QML2_IMPORT_PATH:-}"
export QML_IMPORT_PATH="\$QML2_IMPORT_PATH"
exec "$INSTALL_DIR/cli.sh" "\$@"
EOF
chmod +x "$LAUNCHER"

# Avisar si hay un launcher en /usr/local/bin que vaya a tomar precedencia
if [[ -f /usr/local/bin/ambxst ]]; then
    warn "/usr/local/bin/ambxst existe y puede tener prioridad sobre el tuyo."
    warn "Borralo con:   sudo rm /usr/local/bin/ambxst"
fi

# === 7. PATH sanity ===
case ":$PATH:" in
    *":$LAUNCHER_DIR:"*) ok "$LAUNCHER_DIR está en PATH." ;;
    *) warn "$LAUNCHER_DIR NO está en PATH. Agregá esto a ~/.zshrc o ~/.bashrc:"
       warn "    export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

# === Cierre ===
ok "Listo."
cat <<EOF

  Fuente:    $INSTALL_DIR
  Launcher:  $LAUNCHER
  Config:    \$HOME/.config/ambxst/config/

  → Editá libremente cualquier .qml en $INSTALL_DIR/modules/
    Quickshell hot-recarga QML al guardar (no hace falta reinstalar).

  → Actualizar desde upstream sin perder tus cambios:
      cd $INSTALL_DIR
      git fetch upstream
      git rebase upstream/$BRANCH      # o: git merge upstream/$BRANCH

  → Integración con Hyprland (desde DENTRO de una sesión Hyprland):
      ambxst install hyprland

  → Correr:
      ambxst
EOF

if [[ $WITH_HYPRLAND -eq 1 ]]; then
cat <<EOF

  ⚠  Hyprland recién instalado — para que aparezca en el selector de sesión:
       sudo systemctl restart sddm        # o gdm / lightdm, según uses
     Después logueate eligiendo "Hyprland" en el selector.
EOF
fi
