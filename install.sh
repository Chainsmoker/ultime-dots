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

for dir in "$SRC"/*/; do
    name=$(basename "$dir")
    target="$DST/$name"

    if [[ -L "$target" ]]; then
        # ya es symlink — asegurarse que apunta acá
        if [[ "$(readlink "$target")" != "$dir"* ]]; then
            warn "$target ya es symlink pero a otro lado. Backup."
            mv "$target" "$target.dotfiles-bak"
        else
            ok "$target ya linkeado correctamente"
            continue
        fi
    elif [[ -e "$target" ]]; then
        warn "$target existe — moviendo a $target.dotfiles-bak"
        mv "$target" "$target.dotfiles-bak"
    fi

    # linkear archivo por archivo (no la carpeta entera)
    mkdir -p "$target"
    for file in "$dir"*; do
        fname=$(basename "$file")
        link="$target/$fname"
        if [[ -e "$link" && ! -L "$link" ]]; then
            mv "$link" "$link.dotfiles-bak"
        fi
        ln -sf "$file" "$link"
        ok "linked $link"
    done
done

echo
ok "Listo. Editá ~/.config/* normalmente — son symlinks a este repo."
