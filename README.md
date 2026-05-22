# dotfiles

Mi configuración para Linux + Hyprland + [Ambxst](https://github.com/Axenide/Ambxst).
Configs portadas / inspiradas en [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), adaptadas para usar Ambxst como shell en lugar de illogical-impulse.

## Qué hay

| Carpeta / archivo | Origen | Notas |
|---|---|---|
| `config/hypr/` | end-4 (adaptado) | Hyprland config. Animaciones, blur, gestures de end-4. Keybinds genéricos. Autostart de Ambxst. |
| `config/kitty/` | end-4 | Terminal. **Comentado** el include de theme generado por illogical-impulse. |
| `config/fuzzel/` | end-4 | Launcher fallback. Theme con colores hardcodeados. |
| `config/foot/` | end-4 | Terminal alternativo. |
| `config/mpv/` | end-4 | Video player. |
| `config/wlogout/` | end-4 | Menú de salida (lock/logout/reboot/shutdown). |
| `config/fontconfig/` | end-4 | Sustitución de fuentes. |
| `config/xdg-desktop-portal/` | end-4 | Portal Hyprland para screen share / file pickers. |
| `config/zshrc.d/` | end-4 | Snippets de zsh. `auto-Hypr.sh` fixed para usar `Hyprland` real (no `start-hyprland`). |
| `config/starship.toml` | end-4 | Prompt para starship. |
| `config/{chrome,code,thorium}-flags.conf` | end-4 | Flags para Wayland nativo. |

## Lo que NO traje (a propósito)

| | Motivo |
|---|---|
| `matugen/` | Generador de colores de end-4. No lo usamos. |
| `quickshell/` | end-4 shell illogical-impulse — reemplazado por Ambxst. |
| `Kvantum/`, `kde-material-you-colors/`, `kdeglobals`, `konsolerc`, `dolphinrc`, `darklyrc` | Todos dependen de colores generados por matugen. Rotos sin él. |
| `fish/` | Uso zsh. |

## Instalación en máquina nueva

```bash
git clone https://github.com/<vos>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinkea `~/dotfiles/config/*` a `~/.config/*`. Backupea cualquier archivo existente como `*.dotfiles-bak` antes de pisar.

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
- [ ] Theming de kitty: portar o configurar matugen, o hardcodear paleta.
- [ ] Workspaces / multi-monitor config si lo amerita.
