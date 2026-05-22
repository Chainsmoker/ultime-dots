# Auto start Hyprland on tty1
# Nota: si usás display manager (sddm/gdm) este bloque NO se dispara — $DISPLAY ya está seteado.
if [ -z "$DISPLAY" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
  mkdir -p ~/.cache
  exec Hyprland > ~/.cache/hyprland.log 2>&1
fi
