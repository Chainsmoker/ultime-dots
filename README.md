# dotfiles

Mi configuración para Linux + Hyprland + [Ambxst](https://github.com/Axenide/Ambxst).

## Qué hay

- `config/hypr/` → Hyprland config. Inspirado en [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (curves de animación, decoration, gestures) pero adaptado para usar **Ambxst** como shell en lugar de illogical-impulse.

## Cómo se instala en una máquina nueva

```bash
git clone https://github.com/<tu-usuario>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` crea symlinks de `~/dotfiles/config/*` a `~/.config/*`, así que cuando editás un archivo en `~/.config/hypr/hyprland.conf` estás editando este repo.

## Cómo editar

Los archivos en `~/.config/` son symlinks a este repo. Editás como siempre:

```bash
$EDITOR ~/.config/hypr/hyprland.conf
```

Y después:

```bash
cd ~/dotfiles
git add -A
git commit -m "tweak: ..."
git push
```

## Stack

- **Compositor**: Hyprland
- **Shell / barra / launcher**: [Ambxst](https://github.com/Axenide/Ambxst) (Quickshell-based)
- **Terminal**: kitty
- **Launcher fallback**: fuzzel
- **Notifications**: Ambxst built-in
- **Clipboard**: cliphist + wl-clipboard

## Créditos

- end-4 / dots-hyprland — base de animation curves y decoration values.
- Axenide / Ambxst — la shell que corre encima.
