# zshrc — Configuración de Zsh para ultime-dots (Nix-free)

# Ruta a tu instalación de Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Tema y plugins de Oh My Zsh
ZSH_THEME="archcraft"
plugins=(git sudo)

# Carpeta Oh My Zsh Custom (se linkea automáticamente a config/zsh-custom)
export ZSH_CUSTOM="$ZSH/custom"

# Cargar Oh My Zsh si está instalado
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Exportar PATH y Editor por defecto
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias cat='bat --style=plain'
alias l='eza -CF'
alias la='eza -A'
alias ll='eza -alF'
alias ls='eza --icons --group-directories-first'

# Cargar plugins si están instalados a nivel de sistema (Arch Linux pacman)
for plugin in zsh-syntax-highlighting/zsh-syntax-highlighting.zsh zsh-autosuggestions/zsh-autosuggestions.zsh; do
    if [[ -f "/usr/share/zsh/plugins/$plugin" ]]; then
        source "/usr/share/zsh/plugins/$plugin"
    fi
done

# Cargar los snippets dinámicos de zshrc.d (como la variable EDITOR de Helix)
if [[ -d "$HOME/.config/zshrc.d" ]]; then
    for f in "$HOME"/.config/zshrc.d/*.zsh; do
        source "$f"
    done
fi
