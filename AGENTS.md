# ultime-dots — PROJECT KNOWLEDGE BASE

Dotfiles personales para Linux con Hyprland + Ambxst shell + Material You dinámico vía matugen.

## OVERVIEW

Este repo no es solo configs: incluye **dos forks parchados** (Ambxst y axctl) y **scripts de glue** para integrarlos. La filosofía es:

1. **Configs como symlinks** — `~/dotfiles/config/*` se linkean a `~/.config/*` con `install.sh`. Editás cualquier archivo de `~/.config/` y editás este repo automáticamente.
2. **Theming dinámico** — el wallpaper define la paleta. `matugen` regenera colores, Hyprland los carga vía `source =`, GTK los toma vía `gtk.css`, kitty vía `include`, Papirus folders se recolorean automáticamente.
3. **Forks separados** — Ambxst (shell QML) y axctl (compositor IPC en Go) viven en `Chainsmoker/Ambxst` y `Chainsmoker/axctl` respectivamente, fuera de este repo. `install-ambxst.sh` los clona y los compila.

## STRUCTURE

```
ultime-dots/
├── AGENTS.md                 ← este archivo
├── UPDATE.md                 ← cómo sincronizar con upstream
├── README.md                 ← intro pública
├── install.sh                ← crea symlinks config/* → ~/.config/*
├── install-ambxst.sh         ← instala Hyprland, deps, axctl compilado, Ambxst
├── bin/                      ← scripts que viven en ~/.local/bin
│   ├── wall                  ← cambiar wallpaper + regenerar paleta
│   ├── apply-folder-color    ← mapea accent matugen → preset Papirus folders
│   └── AGENTS.md
└── config/                   ← se mappea a ~/.config/
    ├── hypr/                 ← Hyprland (window manager)
    ├── matugen/              ← templates para generar colors.conf, gtk.css, etc.
    ├── gtk-3.0/, gtk-4.0/    ← settings.ini + gtk-extra.css (estilos translúcidos)
    ├── kitty/, foot/         ← terminales
    ├── fuzzel/               ← launcher fallback
    ├── wlogout/              ← menú salir
    ├── zshrc.d/              ← snippets bash/zsh (incluye fix kitty-terminfo)
    ├── zsh-custom/           ← oh-my-zsh custom (sigue cargado por nix-zshrc)
    ├── fontconfig/           ← font fallbacks
    ├── xdg-desktop-portal/   ← portal Hyprland
    ├── mpv/                  ← video player
    ├── starship.toml         ← prompt
    ├── *-flags.conf          ← Chrome/Code/Thorium flags Wayland nativo
    └── AGENTS.md
```

Cada subcarpeta crítica tiene su propio AGENTS.md.

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| **Entry point install** | `install.sh` | Itera `config/*/` y symlinkea archivo por archivo. Backupea conflictos con sufijo `.bak-<timestamp>` |
| **Install completo desde cero** | `install-ambxst.sh` | Arch + Hyprland + axctl patched + Ambxst patched + sudoers Papirus + gsettings defaults |
| **Theming dinámico (matugen)** | `config/matugen/config.toml` + `templates/` | Lista de output paths y templates Liquid |
| **Hook de regenerar paleta** | `bin/wall` | Wallpaper → matugen → hyprctl reload → kitty SIGUSR1 → apply-folder-color |
| **Folder color por hue** | `bin/apply-folder-color` | Lee `accent_color` del gtk.css y mapea hue (0-360) → preset Papirus |
| **GTK no-overwrite por Ambxst** | `config/gtk-4.0/gtk-extra.css` | Cargado vía `@import` al principio del gtk.css que Ambxst regenera |
| **Hyprland source matugen** | `config/hypr/hyprland.conf:source = colors.conf` | DEBE estar después del bloque `general {}` para que matugen overridea |
| **Sudoers NOPASSWD Papirus** | Instalado por `install-ambxst.sh` § 8 | `/etc/sudoers.d/papirus-folders` |

## ARQUITECTURA DEL THEMING

```
   wallpaper image
        ↓
   matugen (con ~/.config/matugen/config.toml)
        ↓
   genera múltiples outputs:
   ├── ~/.config/hypr/colors.conf       (Hyprland: borders + bg)
   ├── ~/.config/gtk-3.0/gtk.css        (GTK3: M3 colors)
   ├── ~/.config/gtk-4.0/gtk.css        (GTK4: M3 colors + Nautilus styles)
   ├── ~/.config/kitty/colors.conf      (kitty: 16-color ANSI palette)
   ├── ~/.config/fuzzel/fuzzel_theme.ini (fuzzel)
   └── ~/.config/hypr/hyprlock/colors.conf

   Ambxst GtkGenerator.qml ALSO sobreescribe gtk-{3,4}.0/gtk.css
   con sus propios @define-color al cambiar wallpaper desde el dashboard.
   El patch en Chainsmoker/Ambxst hace que prepende:
       @import url("file://.../gtk-4.0/gtk-extra.css");
   → tus estilos custom en gtk-extra.css sobreviven a la regeneración.
```

## CONVENTIONS

- **No tocar `gtk.css`** generado por matugen/Ambxst directamente. Estilos custom van en `gtk-extra.css`.
- **Símbolos `@`** en gtk-extra.css se resuelven en runtime — usá `@accent_color`, `@window_bg_color`, `@surface_container` etc.
- **Hyprland config**: `source = ~/.config/hypr/colors.conf` SIEMPRE al FINAL del archivo o después de los bloques que querés que matugen sobreescriba.
- **install.sh idempotente**: detecta dirs ya linkeadas y no las re-toca. Para forzar refresh, borrá el symlink antes.
- **bin/** scripts deben ser self-contained y manejables sin Ambxst corriendo (ej. `wall` arranca sola, no depende de IPC de Ambxst).
- **Variables editables en hyprland.conf** se declaran con `$mod`, `$terminal`, `$browser`, etc. al principio del archivo. Reemplazá ahí, no en cada keybind.

## ANTI-PATTERNS

- ❌ **Editar `~/.config/gtk-4.0/gtk.css`** — se sobreescribe en cada cambio de wallpaper. Editá la template en `config/matugen/templates/gtk-4.0/gtk.css` o `config/gtk-4.0/gtk-extra.css`.
- ❌ **Agregar carpetas a `config/` que no sean parte de tu config personal** — `install.sh` las symlinkea automáticamente. No metas `Cache/`, `state/`, etc.
- ❌ **Hardcodear paths absolutos en `bin/`** — usá `$HOME` y `$XDG_*` env vars para que sea portable a otra máquina.
- ❌ **Arrancar `axctl daemon` manualmente** desde `hyprland.conf` con `exec-once` — Ambxst spawnea su propio daemon vía `AxctlService.qml`. Tener dos hace que ambos compitan por el socket `/tmp/axctl-1000.sock` y los widgets dejan de responder a clicks.
- ❌ **Patchear directamente `~/Repos/Ambxst/`** sin commit — perdés los cambios cuando el script de update hace `git checkout`. Trabajá siempre en la branch `feat/always-show-player` del fork `Chainsmoker/Ambxst` y hacé commits.

## FORKS RELACIONADOS

- **`Chainsmoker/Ambxst`** branch `feat/always-show-player` — shell QML con UX patches:
  - CompactPlayer: muestra player cuando hay media activa
  - PositionSlider: ondas más gruesas
  - Workspaces: Button → Item para que clicks lleguen
  - OverviewWindow: sin focus-on-hover (cursor warp)
  - ScrollingWorkspace: single-tap en empty workspace
  - GtkGenerator: prepende @import gtk-extra.css y llama apply-folder-color
  - SideNotch + ChatPanel (en `modules/widgets/controlpanel/`)

- **`Chainsmoker/axctl`** branch `fix/hyprland-dispatcher` — fix Go que reemplaza `hl.dsp.*` (Lua scripting) por `dispatch workspace/togglespecialworkspace` plain. Sin esto, `axctl workspace switch N` retorna "Success" pero no hace nada en Hyprland mainline (Axenide/axctl#3, PR Axenide/axctl#5).
