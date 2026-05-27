# term-fetch — random pokemon art on terminal startup
# Sourced by oh-my-zsh via ~/.oh-my-zsh/custom/*.zsh
# Absolute path because ~/.local/bin isn't in PATH yet when oh-my-zsh custom runs

if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
    "$HOME/.local/bin/term-fetch" 2>/dev/null || true
fi
