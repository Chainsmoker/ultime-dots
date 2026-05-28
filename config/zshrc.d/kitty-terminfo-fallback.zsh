# Fallback cuando el terminfo de kitty no existe en el sistema actual.
# Caso típico: SSH desde kitty a una máquina remota que no tiene kitty-terminfo.
# Sin esto, `clear`, `tput`, etc tiran "xterm-kitty: unknown terminal type".
if [[ "$TERM" == "xterm-kitty" ]] && ! infocmp xterm-kitty &>/dev/null; then
    export TERM=xterm-256color
fi

# Para SSH a remotos sin kitty-terminfo: usar `kitten ssh` (copia el terminfo de
# kitty al host automáticamente y conserva colores/teclas en terminales capaces).
# Cae a `ssh` normal fuera de kitty. Mejor que forzar TERM=xterm-256color en TODO
# host, que degradaba la sesión incluso en remotos que sí soportan kitty.
if [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten >/dev/null 2>&1; then
    alias ssh='kitten ssh'
fi
