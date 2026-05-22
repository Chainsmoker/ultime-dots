# hypr/ — Hyprland Configuration

## OVERVIEW

Configuración de Hyprland (Wayland compositor) inspirada en end-4/dots-hyprland (animation curves + decoration + gestures). Adaptada para usar Ambxst como shell.

## STRUCTURE

- `hyprland.conf` — config principal. Variables, monitor, env, autostart, general, decoration, animations, dwindle, input, gestures, misc, binds, cursor, xwayland, keybinds. **`source = ~/.config/hypr/colors.conf` AL FINAL** para que matugen overridea los colores definidos en `general{}`.
- `hyprlock.conf` (si existe, vía Ambxst) — pantalla de bloqueo.

## WHERE TO LOOK

| Tarea | Ubicación | Notas |
|---|---|---|
| Cambiar terminal default | `hyprland.conf:11` `$terminal = ...` | Reemplaza globalmente (todos los keybinds lo usan) |
| Cambiar browser | `hyprland.conf:12` `$browser = ...` | |
| Atajos del compositor | `hyprland.conf:220+` Keybinds section | Apps, foco, workspaces 1-10, screenshots, media, suspend |
| Atajo launcher Ambxst | `hyprland.conf:234` SUPER+D | `echo launcher > /tmp/ambxst_ipc.pipe` |
| Border size + colors | `hyprland.conf:69-72` (defaults) + `colors.conf` (matugen override) | size=2, active=accent@DD opacity, inactive=outline@55 |
| Animaciones | `hyprland.conf:113-140` | OutBack overshoot 1.1 estilo Material 3, importadas de end-4 |
| Gestures touchpad | `hyprland.conf:177-181` | 3 dedos workspace / move / fullscreen, 4 dedos workspace swipe |
| Autostart apps | `hyprland.conf:37-44` exec-once | polkit, dbus, gnome-keyring, cliphist, nm-applet, blueman, ambxst |

## SOURCE ORDER MATTERS

```
general {                     ← defaults hardcoded
    border_size = 2
    col.active_border   = rgba(0DB7D4AA)   ← fallback si matugen no arrancó
    col.inactive_border = rgba(31313666)
    ...
}

source = ~/.config/hypr/colors.conf   ← AL FINAL — matugen overridea active/inactive
```

Si movés el `source =` ARRIBA del `general {}`, los hardcoded ganan y el matugen no aplica. **Esto fue un bug histórico** — quedó documentado en el bloque comentado del archivo.

## CONVENTIONS

- **Variables al inicio**: `$mod`, `$terminal`, `$browser`, `$files`, `$editor`, `$launcher`. Cambiar app default es de UNA LÍNEA.
- **Capas de keybinds**: Apps → Window focus → Window state → Workspaces → Special workspace → Drag/Resize → Audio → Media → Brillo → Screenshots → Clipboard → Sesión.
- **Sin keybinds de Ambxst hardcoded**: usá el IPC pipe `/tmp/ambxst_ipc.pipe` o el dispatcher `qs -c ambxst ipc call`. El launcher es `echo launcher > /tmp/ambxst_ipc.pipe`.
- **Section ORDER importa**: `env` antes que `exec-once` (las apps se startean con esas env), `general` y `decoration` antes de `source colors.conf`.

## ANTI-PATTERNS

- ❌ **`source = colors.conf` arriba** — los colors hardcoded ganan.
- ❌ **`exec-once = axctl daemon`** — Ambxst spawnea su propio daemon vía AxctlService.qml. Dos daemons → click handlers rotos.
- ❌ **`windowrulev2`** — está deprecated en Hyprland 0.49+. Pero la sintaxis nueva de `windowrule` cambió y no la tenemos resuelta. Por ahora sin reglas (TODO).
- ❌ **Hardcodear keybinds del launcher en hyprland.conf** — usar IPC. Cambiar el launcher no requiere editar el config del compositor.

## VERSIONES PROBADAS

- Hyprland `0.55.2` (Arch mainline, sin plugins)
- axctl `fix/hyprland-dispatcher` build local
- Ambxst `Chainsmoker/Ambxst:feat/always-show-player`

## REGENERAR PALETA

```bash
wall ~/Pictures/foo.jpg          # dark mode default
wall ~/Pictures/foo.jpg light    # light mode
```

`wall` corre matugen → escribe `colors.conf` → `hyprctl reload` → Hyprland toma colors nuevos.
