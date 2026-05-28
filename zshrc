# zshrc — Configuración de Zsh para ultime-dots (Nix-free)

# Ruta a tu instalación de Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Prompt: si starship está instalado lo usamos (ver init más abajo) y dejamos
# que omz NO pinte su propio prompt; si no, cae al tema archcraft (portable).
if command -v starship >/dev/null; then ZSH_THEME=""; else ZSH_THEME="archcraft"; fi
plugins=(git sudo)

# Carpeta Oh My Zsh Custom (se linkea automáticamente a config/zsh-custom)
export ZSH_CUSTOM="$ZSH/custom"

# Cargar Oh My Zsh si está instalado (esto ya corre compinit)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Prompt starship (después de omz para que gane). Lee ~/.config/starship.toml.
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
