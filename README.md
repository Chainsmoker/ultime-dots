# dotfiles

Mi configuración para Linux + Hyprland + [Ambxst](https://github.com/Axenide/Ambxst).
Configs portadas / inspiradas en [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), adaptadas para usar Ambxst como shell en lugar de illogical-impulse.

## Qué hay

| Carpeta / archivo | Origen | Notas |
|---|---|---|
| `config/hypr/` | end-4 (adaptado) | Hyprland config. Animaciones, blur, gestures de end-4. Keybinds genéricos. Autostart de Ambxst. |
| `config/kitty/` | end-4 | Terminal. Theme dinámico vía matugen (`include ./colors.conf`). |
| `config/fuzzel/` | end-4 | Launcher fallback. Theme dinámico generado por matugen (`fuzzel_theme.ini`, gitignored). |
| `config/foot/` | end-4 | Terminal alternativo. |
| `config/mpv/` | end-4 | Video player. |
| `config/fontconfig/` | end-4 | Sustitución de fuentes. |
| `config/xdg-desktop-portal/` | end-4 | Portal Hyprland para screen share / file pickers. |
| `config/zshrc.d/` | end-4 | Snippets de zsh. `auto-Hypr.sh` fixed para usar `Hyprland` real (no `start-hyprland`). |
| `config/matugen/templates/starship/` | propio | Prompt de zsh (starship): brutalista, bloques sólidos, recoloreado por matugen. Se genera a `~/.config/starship.toml`. |
| `config/{chrome,code,thorium}-flags.conf` | end-4 | Flags para Wayland nativo. |

## Theming dinámico (matugen)

`config/matugen/` tiene templates Material You que generan colores desde el wallpaper. Templates activos:

- `hyprland/colors.conf` → `~/.config/hypr/colors.conf` (borders, background)
- `kitty/colors.conf` → `~/.config/kitty/colors.conf` (16 colores ANSI)
- `fuzzel/fuzzel_theme.ini` → tema dinámico del launcher
- `gtk-3.0/gtk.css` + `gtk-4.0/gtk.css` → Firefox/Brave/Nautilus
- `hyprland/hyprlock-colors.conf` → pantalla de bloqueo
- `starship/starship.toml` → `~/.config/starship.toml` (prompt de zsh, brutalista)

> Los outputs generados (`fuzzel_theme.ini`, `colors.conf`, `starship.toml`, …) están **gitignored**: versionamos los templates, no la salida. Por eso no hay commits de "regenerate colors".

Cambiar wallpaper + regenerar paleta:

```bash
wall ~/Pictures/algo.jpg          # modo dark por defecto
wall ~/Pictures/algo.jpg light    # modo light
```

`bin/wall` corre matugen, reloadea Hyprland y le manda SIGUSR1 a kitty.

## Lo que NO traje (todavía)

| | Motivo |
|---|---|
| `quickshell/` | end-4 shell illogical-impulse — reemplazado por Ambxst. |
| `kde-material-you-colors/`, `kdeglobals`, `konsolerc`, `dolphinrc`, `darklyrc` | Para apps Qt/KDE. Stack adicional, lo armamos cuando hagan falta. |
| `fish/` | Uso zsh. |

## Instalación en máquina nueva

> ℹ️ El repo queda **clonado en la máquina**: los archivos de `~/.config` son
> symlinks que apuntan adentro del repo, así que no lo borres después. El
> one-liner igual lo clona por vos — no hace falta clonar a mano.

**Un solo comando** (Arch Linux — clona + instala todo):

```bash
curl -fsSL https://raw.githubusercontent.com/Chainsmoker/ultime-dots/main/bootstrap.sh | bash
# con Hyprland incluido:
curl -fsSL https://raw.githubusercontent.com/Chainsmoker/ultime-dots/main/bootstrap.sh | bash -s -- --with-hyprland
```

**O a mano**, dos pasos:

```bash
git clone https://github.com/Chainsmoker/ultime-dots.git ~/dotfiles
cd ~/dotfiles

# 1) Apps + Ambxst + matugen + fuentes (paquete grande).
#    Agregá --with-hyprland si Hyprland todavía no está instalado.
bash install-ambxst.sh            # o: bash install-ambxst.sh --with-hyprland

# 2) Symlinkear los dotfiles + deps del file-picker + generar temas iniciales
./install.sh
```

`install.sh` symlinkea `~/dotfiles/config/*` a `~/.config/*` (backupea lo existente como `*.bak-<timestamp>`), instala las deps del portal/picker y corre un `matugen` inicial para que los temas existan en el primer arranque. Cambiá la paleta cuando quieras con `wall <imagen>`.

## Edición

Los archivos en `~/.config/` son symlinks. Editás como siempre:

```bash
$EDITOR ~/.config/hypr/hyprland.conf
```

Cuando guardás, estás editando este repo. Después:

```bash
cd ~/dotfiles
git add -A && git commit -m "tweak: ..."
git push
```

## Stack

- Compositor: **Hyprland**
- Shell / barra / launcher / notch: **[Ambxst](https://github.com/Axenide/Ambxst)** (Quickshell-based)
- Terminal: **kitty**
- Launcher fallback: **fuzzel**
- Prompt: **starship**
- Shell: **zsh**

## Créditos

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — base de animation curves, decoration, gestures, configs de apps.
- [Axenide/Ambxst](https://github.com/Axenide/Ambxst) — la shell.

## TODO

- [ ] Restaurar `windowrule`s cuando descubra la sintaxis para Hyprland 0.55+.
- [ ] Workspaces / multi-monitor config si lo amerita.
