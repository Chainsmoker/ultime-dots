# gtk-4.0/ — GTK4 Theme Configuration

## OVERVIEW

Configs y CSS extension para GTK4 (Nautilus, GNOME apps modernas, Brave portal dialogs, etc.). La integración con matugen es la parte interesante — hay TRES capas que escriben al mismo `gtk.css`.

## STRUCTURE

| Archivo | Generado por | Editable a mano? |
|---|---|---|
| `settings.ini` | nosotros (config en este repo) | ✅ |
| `gtk-extra.css` | nosotros (config en este repo) | ✅ — overrides custom |
| `gtk.css` | matugen (via `wall`) o Ambxst GtkGenerator (via dashboard) | ❌ — se sobreescribe |

## EL PROBLEMA DEL `gtk.css` DOBLE-ESCRITO

Dos cosas escriben a `~/.config/gtk-4.0/gtk.css`:

1. **`matugen` (vía `wall`)** — escribe la versión LARGA usando `matugen/templates/gtk-4.0/gtk.css` (incluye @define-color + estilos Nautilus inline).
2. **Ambxst `GtkGenerator.qml` (vía dashboard wallpaper change)** — escribe la versión CORTA con solo @define-color de los M3 roles principales.

Si Ambxst regenera, los estilos largos se pierden. Para resolver esto:

> El fork `Chainsmoker/Ambxst:feat/always-show-player` modifica `GtkGenerator.qml` para que prepende `@import url("file:///.../gtk-4.0/gtk-extra.css");` al principio del gtk.css que escribe. Los @define-color vienen después → el cascade de GTK aplica nuestros estilos contra los colores actuales.

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| Cambiar icon-theme o cursor | `settings.ini` | Restart Nautilus para tomar |
| Window background translúcido | `gtk-extra.css:9-13` | `alpha(@window_bg_color, 0.78)` |
| Headerbar opacity | `gtk-extra.css:16-20` | |
| Sidebar transparente Nautilus | `gtk-extra.css:23-27` | `placessidebar` + `.navigation-sidebar` |
| Path bar con accent | `gtk-extra.css:35-46` | `alpha(@accent_color, 0.12)` |

## EL FLUJO COMPLETO

```
   wallpaper change
        ↓
   ┌─────────────────────────────┐
   │ wall script               OR  │
   │   matugen → gtk.css largo │
   │   con estilos inline     │
   └─────────────────────────────┘
        ↓ (o)
   ┌─────────────────────────────┐
   │ Ambxst dashboard            │
   │   matugen → colors.json    │
   │   GtkGenerator.qml         │
   │   → gtk.css CORTO con:      │
   │   '@import gtk-extra.css'  │
   │   + @define-color M3        │
   └─────────────────────────────┘
        ↓
   En cualquiera de los dos casos:
   gtk.css final tiene los @define-color actualizados
   + (vía @import) los estilos custom de gtk-extra.css
```

## CONVENTIONS

- **Estilos custom en gtk-extra.css** — esos son los que sobreviven a TODOS los flows. No agregar nada a la template de matugen.
- **Usar `alpha(@color, opacity)`** para mantenerlo consistente con los M3 colors que vienen del wallpaper. NO hardcodear hex.
- **Override .nautilus-pathbar, .navigation-sidebar etc.** son los selectores que Nautilus expone — buscar más en GTK Inspector si necesitás más.

## ANTI-PATTERNS

- ❌ **Editar `gtk.css` directamente** — se sobreescribe.
- ❌ **Hardcodear colores hex en gtk-extra.css** — pierden la integración con el wallpaper.
- ❌ **Usar `!important`** — el cascade está pensado para que gtk-extra.css gane naturalmente (carga al inicio + selectores específicos). Si necesitás `!important`, revisar el orden de carga.
- ❌ **Cambiar `gsettings gtk-theme` a algo distinto de `adw-gtk3` o `adw-gtk3-dark`** — los @define-color del matugen están pensados para esos themes.

## TEST RÁPIDO

```bash
# Verificar que el @import está en el gtk.css generado:
head -3 ~/.config/gtk-4.0/gtk.css | grep "@import.*gtk-extra"

# Si está, todo bien. Si no, Ambxst no aplicó el patch — verificar fork.
```
