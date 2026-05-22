# Fallback cuando el terminfo de kitty no existe en el sistema actual.
# Caso típico: SSH desde kitty a una máquina remota que no tiene kitty-terminfo.
# Sin esto, `clear`, `tput`, etc tiran "xterm-kitty: unknown terminal type".
if [[ "$TERM" == "xterm-kitty" ]] && ! infocmp xterm-kitty &>/dev/null; then
    export TERM=xterm-256color
fi

# Bonus: si SSHeás a remotos, exportar TERM=xterm-256color para esa sesión.
# Esto evita el problema sin cambiar tu TERM local.
alias ssh='TERM=xterm-256color ssh'
