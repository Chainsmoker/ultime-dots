# config/ — Application Configs

## OVERVIEW

Cada subcarpeta de `config/` se symlinkea a `~/.config/<nombre>/` por `install.sh`. Los archivos sueltos (ej. `starship.toml`) van directo a `~/.config/<archivo>`. Editás un archivo en `~/.config/` y estás editando este repo.

## STRUCTURE

| Carpeta / archivo | Destino | Rol |
|---|---|---|
| `hypr/` | `~/.config/hypr/` | Hyprland (compositor). Ver hypr/AGENTS.md |
| `matugen/` | `~/.config/matugen/` | Templates para generar paletas. Ver matugen/AGENTS.md |
| `gtk-3.0/` `gtk-4.0/` | `~/.config/gtk-{3,4}.0/` | settings.ini + gtk-extra.css. Ver gtk-4.0/AGENTS.md |
| `kitty/` | `~/.config/kitty/` | Terminal default. Include `./colors.conf` (generado por matugen) |
| `foot/` | `~/.config/foot/` | Terminal alternativo |
| `fuzzel/` | `~/.config/fuzzel/` | Launcher fallback. fuzzel_theme.ini regenerado por matugen |
| `wlogout/` | `~/.config/wlogout/` | Menú salir. layout + style.css |
| `zshrc.d/` | `~/.config/zshrc.d/` | Snippets que home-manager sourcea |
| `zsh-custom/` | `~/.oh-my-zsh/custom/` | oh-my-zsh customs (auto-sourced). Fix kitty-terminfo vive acá |
| `fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` | Sustituciones de fuentes |
| `xdg-desktop-portal/hyprland-portals.conf` | `~/.config/xdg-desktop-portal/` | Portal para screen share / file pickers |
| `mpv/mpv.conf` | `~/.config/mpv/mpv.conf` | Video player |
| `starship.toml` | `~/.config/starship.toml` | Prompt (cross-shell) |
| `chrome-flags.conf` `code-flags.conf` `thorium-flags.conf` | `~/.config/` | Flags Wayland nativo para Brave/Code/Thorium. **Sin `--gtk-version=4`** para que el FileChooser pase por el portal. |
| `Kvantum/` | `~/.config/Kvantum/` | Qt widget style. `theme=KvMojave` (translucent + blur). |
| `xdg-desktop-portal-termfilechooser/` | `~/.config/xdg-desktop-portal-termfilechooser/` | Config del portal File Picker. `cmd=yazi-portal-wrapper` (ver `bin/`). |
| `yazi/` | `~/.config/yazi/` | TUI file manager. `yazi.toml` + `keymap.toml` trackeados; `theme.toml` matugen-generado (no trackear). |
| `systemd/user/` | `~/.config/systemd/user/` | User units custom — `hyprland-session.target` (BindsTo graphical-session) + overrides de portales. |

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| Apariencia general (dark/light, fuentes) | `gtk-3.0/settings.ini` + `gtk-4.0/settings.ini` | Icon theme=Papirus-Dark, theme=adw-gtk3-dark |
| Atajos del compositor | `hypr/hyprland.conf:222+` | Keybinds bajo "Keybinds" |
| Animaciones Hyprland | `hypr/hyprland.conf` `bezier` + `animations` | Curves Material 3 importados de end-4 |
| Terminal colores | `kitty/kitty.conf:7` | `include ./colors.conf` (matugen) |
| Atajos zsh + alias | `zshrc.d/*.zsh` | Sourceado por home-manager .zshrc |
| Fallback kitty terminfo | `zsh-custom/kitty-terminfo-fallback.zsh` | Auto-set TERM=xterm-256color al SSH |
| File picker estilo (yazi colors) | `matugen/templates/yazi/theme.toml` | Regenerado por `wall`. Bind matugen → yazi palette. |
| File picker terminal | `xdg-desktop-portal-termfilechooser/config` | `cmd=yazi-portal-wrapper`. Cambiar `default_dir` o `create_help_file` acá. |
| Hyprland-session.target wrapper | `systemd/user/hyprland-session.target` | Wrapper `BindsTo=graphical-session.target` — sin esto, portales fallan |

## INTEGRACIÓN CON OTRAS PARTES DEL REPO

```
   install.sh
        ↓ symlinkea config/*/* a ~/.config/*/*
   ~/.config/
        ↓
   apps los leen (kitty, hyprland, ...)
        ↑
   matugen reescribe los archivos generados
   (~/.config/gtk-{3,4}.0/gtk.css, kitty/colors.conf, etc.)
        ↑
   bin/wall <imagen>     →   dispara la cadena
```

## CONVENTIONS

- **Una carpeta por app**: si una app necesita más de un archivo, va en su carpeta. Si es un solo archivo, va al root de `config/`.
- **No commitear secrets**: las API keys, tokens, etc. NUNCA. Si una config los requiere, usar `_REDACTED` placeholder + documentar setup manual.
- **No commitear estado runtime**: caches, history files, pid files, etc. están en `.gitignore`.
- **Bookmarks personales en GTK** (`gtk-3.0/bookmarks`) NO se symlinkea — install.sh procesa archivo por archivo, NO toca lo que no está en el repo.

## ANTI-PATTERNS

- ❌ **Symlinkear carpetas enteras** en vez de archivo-por-archivo — `install.sh` lo hace adrede para no contaminar `~/.config/<app>/` con archivos del repo que no querés.
- ❌ **Editar archivos generados por matugen** (`gtk.css`, `colors.conf`, `fuzzel_theme.ini`) directamente — se regeneran al cambiar wallpaper. Tus cambios se pierden.
- ❌ **Usar `.bashrc` para zsh-only configs** — usar `.zshrc.d/*.zsh`. home-manager los sourcea automáticamente.
