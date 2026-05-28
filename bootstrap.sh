#!/usr/bin/env bash
# Bootstrap de los dotfiles para una máquina nueva (Arch Linux).
#
# Los archivos de ~/.config son symlinks que viven DENTRO del repo, así que el
# repo tiene que quedar clonado. Este script lo clona (si falta) y corre los dos
# installers en orden. Pensado para ejecutarse vía curl:
#
#   curl -fsSL https://raw.githubusercontent.com/Chainsmoker/ultime-dots/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Chainsmoker/ultime-dots/main/bootstrap.sh | bash -s -- --with-hyprland
#
# Overrides opcionales:
#   DOTFILES_REPO=https://github.com/<vos>/ultime-dots.git
#   DOTFILES_DIR=$HOME/.local/share/dotfiles
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/Chainsmoker/ultime-dots.git}"
# Default nuevo: ~/.local/share/dotfiles. Si ya existe un clone legacy en
# ~/dotfiles (la máquina principal), lo respetamos para no duplicar.
_DEFAULT_DIR="$HOME/.local/share/dotfiles"
[ -d "$HOME/dotfiles/.git" ] && _DEFAULT_DIR="$HOME/dotfiles"
DIR="${DOTFILES_DIR:-$_DEFAULT_DIR}"

command -v pacman >/dev/null || { echo "Este bootstrap es para Arch (pacman no encontrado)." >&2; exit 1; }
command -v git >/dev/null || { echo "→ Instalando git..."; sudo pacman -S --needed --noconfirm git; }

if [ -d "$DIR/.git" ]; then
    echo "→ $DIR ya existe; intento actualizar (ff-only)..."
    git -C "$DIR" pull --ff-only || echo "  (no se pudo fast-forward, sigo con lo que hay)"
else
    echo "→ Clonando $REPO → $DIR..."
    git clone "$REPO" "$DIR"
fi

cd "$DIR"
echo "→ install-ambxst.sh $* (apps + Ambxst + matugen + fuentes)..."
bash install-ambxst.sh "$@"
echo "→ install.sh (symlinks + temas iniciales)..."
./install.sh

echo "✓ Listo. Reiniciá el display manager si instalaste Hyprland, logueate en la sesión Hyprland y corré 'ambxst'."
