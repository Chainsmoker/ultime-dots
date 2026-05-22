# bin/ — Helper Scripts

## OVERVIEW

Scripts que viven en `~/.local/bin/` (linkeados por `install.sh`). Son los **pegamentos entre matugen, Ambxst, Hyprland, kitty, y Papirus**. Sin ellos el theming dinámico no se aplica cross-app cuando cambia el wallpaper.

## STRUCTURE

| Script | Rol |
|---|---|
| `wall` | Setea wallpaper + regenera paleta + recarga apps |
| `apply-folder-color` | Mapea accent matugen → preset color de Papirus folders |

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| Pipeline completo de cambio de wallpaper | `wall:12-32` | matugen → hyprctl → kitty → apply-folder-color |
| Lectura del accent matugen | `apply-folder-color:7-14` | Grep `@define-color accent_color #` del `gtk-3.0/gtk.css` |
| Conversión RGB → HSL hue | `apply-folder-color:17-22` | Python `colorsys.rgb_to_hls` |
| Mapping hue → preset Papirus | `apply-folder-color:24-32` | Buckets de 30-50° aprox, 9 colores totales |
| Cache anti-redundante | `apply-folder-color:36-38` | `~/.cache/dotfiles/last-folder-color`, evita correr sudo si ya está aplicado |
| Invalidación de cache de iconos | `apply-folder-color:46-52` | Toggle `gsettings icon-theme` + `gtk-update-icon-cache` |

## CONVENTIONS

- **Argumentos opcionales**: ambos scripts aceptan args pero también leen estado por defecto. Ej. `apply-folder-color` sin args lee `~/.config/gtk-3.0/gtk.css`.
- **Best-effort en sudo**: usan `sudo -n` (NOPASSWD). Si falla, imprimen el comando exacto a stderr — no abortan el resto del flow.
- **No requieren Ambxst corriendo** — son herramientas standalone que también funcionan en una sesión vainilla.

## HUE → COLOR MAPPING

| Rango hue | Preset Papirus | Color visual |
|---|---|---|
| 0–15° | red | Rojos puros |
| 15–40° | orange | Naranja / dorado oscuro |
| 40–70° | yellow | Amarillo / dorado |
| 70–150° | green | Verdes |
| 150–190° | teal | Verde-azul |
| 190–250° | blue | Azules |
| 250–290° | violet | Violetas |
| 290–330° | pink | Rosas |
| 330–360° | carmine | Rojo profundo |

Si tu wallpaper genera un accent que cae en un bucket inesperado, ajustá los límites en `apply-folder-color:24-32`.

## ANTI-PATTERNS

- ❌ **No mover los scripts a `/usr/local/bin/`** — vivien en `~/.local/bin/` (vía symlink). Mover los rompe los symlinks y obliga a sudo para editarlos.
- ❌ **No agregar logic de wallpaper a `apply-folder-color`** — ese script solo conoce de paletas y folders. Setear wallpaper es responsabilidad de `wall` o del dashboard de Ambxst.
- ❌ **No depender de `python3-XXX` packages** en los scripts — solo `colorsys` (stdlib). Cualquier dep adicional rompe portabilidad.
