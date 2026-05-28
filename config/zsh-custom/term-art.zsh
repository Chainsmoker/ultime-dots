# term-fetch — random pokemon art on terminal startup
# Sourced by oh-my-zsh via ~/.oh-my-zsh/custom/*.zsh
# Absolute path because ~/.local/bin isn't in PATH yet when oh-my-zsh custom runs
#
# El zshrc tiene el MISMO disparador (portable, sin depender de omz); el guard
# _TERM_ART_DONE evita que se dibuje dos veces. Quien corra primero gana.
if [[ -z "${_TERM_ART_DONE:-}" && -n "${KITTY_WINDOW_ID:-}" ]]; then
    _TERM_ART_DONE=1
    "$HOME/.local/bin/term-fetch" 2>/dev/null || true
fi
