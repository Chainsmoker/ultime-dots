# matugen/ — Material You Color Generator

## OVERVIEW

matugen toma una imagen, extrae los colores dominantes con el algoritmo Material You (scheme-tonal-spot por default), y aplica una template Liquid sobre el resultado para escribir archivos de colores en múltiples apps.

## STRUCTURE

```
matugen/
├── config.toml           ← lista templates [templates.X] con input/output paths
├── templates/
│   ├── hyprland/
│   │   ├── colors.conf       ← Hyprland general.col.active_border etc.
│   │   └── hyprlock-colors.conf
│   ├── kitty/colors.conf     ← 16-color ANSI + cursor + selection
│   ├── fuzzel/fuzzel_theme.ini
│   ├── gtk-3.0/gtk.css       ← @define-color M3
│   └── gtk-4.0/gtk.css       ← @define-color M3 + estilos Nautilus inline
```

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| Agregar nueva app al pipeline | `config.toml` | Definir `[templates.<id>]` con `input_path` y `output_path` |
| Cambiar accent color de Hyprland borders | `templates/hyprland/colors.conf` | Toma `{{colors.primary.default.hex_stripped}}` |
| Paleta kitty | `templates/kitty/colors.conf` | Map M3 roles → 16 ANSI slots |
| Bubbles Material 3 GTK4 | `templates/gtk-4.0/gtk.css:7-130` | Light + dark sections |
| Override de Nautilus PathBar | `templates/gtk-4.0/gtk.css:176+` | `#NautilusPathBar` rules |

## SINTAXIS DE TEMPLATES

Liquid templating. Las variables más útiles:

```
{{colors.primary.default.hex}}            → "#ffb59e"
{{colors.primary.default.hex_stripped}}   → "ffb59e"
{{colors.primary.default.red}}            → 255 (decimal)
{{colors.primary.dark.hex}}               → dark variant
{{colors.surface_container.default.hex}}  → tonal surface
```

Roles M3 disponibles: `primary`, `secondary`, `tertiary`, `error`, `background`, `surface`, `surface_container[_low,_high,_highest,_lowest]`, `outline`, `outline_variant`, `inverse_*`, todos con `.light` o `.dark` variants.

## CONFIG.TOML FORMAT

```toml
[config]
version_check = false

[templates.<id>]
input_path = '~/.config/matugen/templates/...'
output_path = '~/.config/.../result.css'
```

## CMDLINE

```bash
matugen image WALLPAPER \
    --mode dark \
    --prefer saturation   # cuando hay múltiples source colors, elegir el más saturado
```

El script `wall` lo invoca con esos defaults. Si querés desde CLI, esos son los flags que funcionan.

## INTERACCIÓN CON AMBXST

Ambxst tiene su PROPIO matugen config en `~/Repos/Ambxst/assets/matugen/config.toml` que solo escribe `~/.cache/ambxst/colors.json` (para la shell QML). NUESTRO matugen (este repo) maneja todo lo demás: gtk, kitty, hyprland, fuzzel.

Pero ambos corren cuando el wallpaper cambia:
- Si cambiás vía dashboard de Ambxst → Ambxst matugen + Ambxst GtkGenerator (sobreescribe gtk.css con sus @define-color, pero PRE-PENDE `@import gtk-extra.css`)
- Si cambiás vía `wall` → solo NUESTRO matugen → escribe gtk.css con la template larga + GtkGenerator no corre

Resultado: el theming termina aplicado en ambas vías. Detalles en `~/dotfiles/config/gtk-4.0/AGENTS.md`.

## ANTI-PATTERNS

- ❌ **Editar los archivos `output_path`** — se sobreescriben en cada `matugen image`. Editá la template (input_path).
- ❌ **Usar `{{colors.primary.hex}}`** (sin `.default`) — formato viejo. Usar siempre `{{colors.primary.default.hex}}` o `.dark`/`.light`.
- ❌ **No remover el `# GENERADO POR MATUGEN`** marker en los templates — sirve de aviso para el siguiente humano que abra el archivo `output_path`.
- ❌ **Cargar `colors.json`** desde shell o app externa — Ambxst es el único que lo lee. Para apps externas, generar un archivo específico en config.toml.
