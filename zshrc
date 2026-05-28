# zshrc — Configuración de Zsh para ultime-dots (Nix-free, sin oh-my-zsh)

# ── Núcleo zsh (reemplaza lo que antes daba oh-my-zsh) ───────────────────────
# Historial
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history hist_expire_dups_first hist_ignore_dups \
       hist_ignore_space hist_verify inc_append_history share_history

# Opciones generales + keybindings estilo emacs (como omz por defecto)
setopt auto_cd interactive_comments
bindkey -e

# Completado: compinit DEBE correr antes de fzf-tab. Rebuild del dump como mucho
# 1 vez al día; si no, se carga cacheado (-C) para que el arranque sea rápido.
autoload -Uz compinit
_zcd="$HOME/.zcompdump"
if [[ -f "$_zcd" && -n "$(find "$_zcd" -mtime -1 2>/dev/null)" ]]; then
    compinit -C -d "$_zcd"
else
    compinit -d "$_zcd"
fi
unset _zcd
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select                          # menú navegable
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colores en el menú
zstyle ':completion:*' group-name ''

# sudo: doble ESC antepone/saca `sudo` a la línea actual (era el plugin `sudo`).
sudo-command-line() {
    [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
    if [[ $BUFFER == sudo\ * ]]; then LBUFFER="${LBUFFER#sudo }"; else LBUFFER="sudo $LBUFFER"; fi
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# Prompt: starship (lee ~/.config/starship.toml).
command -v starship >/dev/null && eval "$(starship init zsh)"

# Exportar PATH y Editor por defecto
typeset -U path PATH          # dedup automático de entradas repetidas en PATH
export PATH="$HOME/.local/bin:$PATH"

# ── Arte en terminal (pokemon) al abrir kitty ───────────────────────────────
# Disparador portable, INDEPENDIENTE de oh-my-zsh. Antes el arte colgaba sólo del
# snippet de zsh-custom que sourcea omz; en un setup sin omz (p.ej. sólo starship)
# nunca corría. En máquinas CON omz ese snippet ya lo disparó antes y comparten
# el guard _TERM_ART_DONE, así que acá no se dibuja doble. Gated a kitty.
if [[ -o interactive && -z "${_TERM_ART_DONE:-}" && -n "${KITTY_WINDOW_ID:-}" && -x "$HOME/.local/bin/term-fetch" ]]; then
    _TERM_ART_DONE=1
    "$HOME/.local/bin/term-fetch" 2>/dev/null || true
fi

# Aliases
alias cat='bat --style=plain'
alias l='eza -CF'
alias la='eza -A'
alias ll='eza -alF'
alias ls='eza --icons --group-directories-first'

# Git — subset más usado del plugin `git` de oh-my-zsh (agregá los que te falten)
alias g='git'
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch'
alias glog='git log --oneline --decorate --graph'
alias glola='git log --oneline --decorate --graph --all'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gsta='git stash'
alias gstp='git stash pop'

# ──────────────────────────────────────────────────────────────────────────
# Plugins externos (nix-free). Se buscan en: clone local → pacman → nix store.
# Si faltan por completo se auto-clonan en ~/.local/share/zsh/plugins (sin sudo,
# portable: en una máquina nueva se instalan solos al abrir la primera shell).
# ──────────────────────────────────────────────────────────────────────────
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"

# Devuelve la ruta al archivo del plugin si existe en alguna ubicación conocida.
_zsh_find_plugin() {
    local name="$1" file="$2" c
    local candidates=(
        "$ZSH_PLUGIN_DIR/$name/$file"
        "/usr/share/zsh/plugins/$name/$file"
        /nix/store/*"-$name"*"/share/$name/$file"(N)
    )
    for c in $candidates; do
        [[ -f "$c" ]] && { print -r -- "$c"; return 0; }
    done
    return 1
}

# Carga un plugin; si no está en ningún lado lo clona y luego lo carga.
_zsh_load_plugin() {
    local name="$1" file="$2" url="$3" path
    if ! path="$(_zsh_find_plugin "$name" "$file")"; then
        command -v git >/dev/null && \
            git clone --depth 1 -q "$url" "$ZSH_PLUGIN_DIR/$name" 2>/dev/null
        path="$(_zsh_find_plugin "$name" "$file")" || return 1
    fi
    source "$path"
}

# ── fzf (configuración "pro") ───────────────────────────────────────────────
if command -v fzf >/dev/null; then
    # Colores derivados del wallpaper (los genera matugen). Define $FZF_THEME_COLORS.
    [[ -f "$HOME/.cache/matugen/fzf-colors.zsh" ]] && source "$HOME/.cache/matugen/fzf-colors.zsh"

    # Origen de archivos: fd si está instalado, si no el walker interno de fzf.
    if command -v fd >/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --margin=1 --padding=1 --info=inline-right --prompt='❯ ' --pointer='▌' --marker='✓ ' --separator='─' --scrollbar='│' --cycle --preview-window='right:55%:border-left:wrap' --bind='ctrl-/:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-y:execute-silent(printf %s {} | wl-copy)' ${FZF_THEME_COLORS}"

    # Ctrl-T → archivos: bat para texto, eza para directorios.
    export FZF_CTRL_T_OPTS="--preview '([[ -d {} ]] && eza -la --icons --color=always --group-directories-first {} || bat --style=numbers --color=always --line-range :300 {}) 2>/dev/null'"
    # Alt-C → cd: listado del directorio destino.
    export FZF_ALT_C_OPTS="--preview 'eza -la --icons --color=always --group-directories-first {} 2>/dev/null'"
    # Ctrl-R → historial con el comando completo en el preview.
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window 'down:3:wrap' --bind 'ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort'"

    # Key-bindings (Ctrl-R/Ctrl-T/Alt-C) + completado. fzf >= 0.48.
    eval "$(fzf --zsh)" 2>/dev/null
fi

# fzf-tab: reemplaza el menú de Tab por una UI de fzf (después de compinit).
# Las instalaciones nix usan el layout share/<name>/; contemplamos ambos.
for _ft in "$HOME/.zsh/plugins/zsh-fzf-tab/share/fzf-tab/fzf-tab.plugin.zsh" \
           "$HOME/.zsh/plugins/zsh-fzf-tab/fzf-tab.plugin.zsh" \
           "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" \
           "/usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"; do
    [[ -f "$_ft" ]] && { source "$_ft"; break; }
done
if ! typeset -f fzf-tab-complete >/dev/null 2>&1 && command -v git >/dev/null; then
    git clone --depth 1 -q https://github.com/Aloxaf/fzf-tab "$ZSH_PLUGIN_DIR/fzf-tab" 2>/dev/null \
        && source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
fi

# zsh-z: salto rápido a directorios visitados (`z proyecto`).
for _z in "$HOME/.zsh/plugins/zsh-z/share/zsh-z/zsh-z.plugin.zsh" \
          "$HOME/.zsh/plugins/zsh-z/zsh-z.plugin.zsh" \
          "$ZSH_PLUGIN_DIR/zsh-z/zsh-z.plugin.zsh" \
          "/usr/share/zsh/plugins/zsh-z/zsh-z.plugin.zsh"; do
    [[ -f "$_z" ]] && { source "$_z"; break; }
done
if ! typeset -f zshz >/dev/null 2>&1 && command -v git >/dev/null; then
    git clone --depth 1 -q https://github.com/agkozak/zsh-z "$ZSH_PLUGIN_DIR/zsh-z" 2>/dev/null \
        && source "$ZSH_PLUGIN_DIR/zsh-z/zsh-z.plugin.zsh"
fi

# Sugerencias inline (gris) basadas en el historial.
_zsh_load_plugin zsh-autosuggestions zsh-autosuggestions.zsh \
    https://github.com/zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# zsh-autoenv: ejecuta .autoenv.zsh al entrar/salir de un directorio.
for _ae in "$HOME/.zsh/plugins/zsh-autoenv/share/zsh-autoenv/autoenv.plugin.zsh" \
           "$HOME/.zsh/plugins/zsh-autoenv/autoenv.plugin.zsh" \
           "$ZSH_PLUGIN_DIR/zsh-autoenv/autoenv.plugin.zsh"; do
    [[ -f "$_ae" ]] && { source "$_ae"; break; }
done

# Cargar los snippets dinámicos de zshrc.d (como la variable EDITOR de Helix)
if [[ -d "$HOME/.config/zshrc.d" ]]; then
    for f in "$HOME"/.config/zshrc.d/*.zsh; do
        source "$f"
    done
fi

# zsh-syntax-highlighting DEBE cargarse al final (envuelve los widgets de ZLE).
_zsh_load_plugin zsh-syntax-highlighting zsh-syntax-highlighting.zsh \
    https://github.com/zsh-users/zsh-syntax-highlighting
