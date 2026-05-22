#!/usr/bin/env bash
# Crea symlinks de ~/dotfiles/config/* hacia ~/.config/*
# Backupea cualquier archivo existente como *.dotfiles-bak antes de pisar.

set -euo pipefail
cd "$(dirname "$0")"
SRC="$PWD/config"
DST="$HOME/.config"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { printf "${GREEN}✔  %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠  %s${NC}\n" "$*"; }

mkdir -p "$DST"

# === Carpetas: linkear archivo por archivo ===
for dir in "$SRC"/*/; do
    name=$(basename "$dir")
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
        ln -sf "$file" "$link"
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

echo
ok "Listo. Editá ~/.config/* normalmente — son symlinks a este repo."
