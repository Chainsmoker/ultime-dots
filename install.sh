#!/usr/bin/env bash
# Crea symlinks de ~/dotfiles/config/* hacia ~/.config/*
# Backupea cualquier archivo existente como *.dotfiles-bak antes de pisar.

set -euo pipefail
cd "$(dirname "$0")"
REPO_ROOT="$PWD"
SRC="$REPO_ROOT/config"
DST="$HOME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { printf "${GREEN}✔  %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠  %s${NC}\n" "$*"; }

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

# === systemd user units (preserva subdirs como *.service.d/override.conf) ===
SYSTEMD_SRC="$SRC/systemd"
SYSTEMD_DST="$DST/systemd"
if [[ -d "$SYSTEMD_SRC" ]]; then
    while IFS= read -r -d '' file; do
        rel="${file#$SYSTEMD_SRC/}"
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

echo
ok "Listo. Editá ~/.config/* normalmente — son symlinks a este repo."
echo
warn "Asegurate de tener ~/.local/bin en tu PATH para los scripts de bin/."
