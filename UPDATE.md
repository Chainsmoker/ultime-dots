# UPDATE.md — Cómo Sincronizar con Upstream

Este repo depende de tres "upstreams" externos. Acá está cómo actualizar cada uno sin perder los parches que tenemos.

## TOC

- [El repo principal (`ultime-dots`)](#1-ultime-dots)
- [Ambxst fork (`Chainsmoker/Ambxst`)](#2-ambxst-fork)
- [axctl fork (`Chainsmoker/axctl`)](#3-axctl-fork)
- [Cuando upstream rompe algo](#troubleshooting)

---

## 1. ultime-dots

Este repo no tiene upstream — es tuyo. Para sincronizar entre máquinas:

```bash
cd ~/dotfiles
git pull            # traer cambios desde otra máquina
git push            # publicar cambios locales
```

Si hay conflictos, resolverlos como cualquier repo normal:

```bash
git status                  # ver qué archivos
$EDITOR archivo-conflicto   # resolver
git add .
git commit
```

---

## 2. Ambxst fork

**Upstream**: `Axenide/Ambxst` (el original)
**Tu fork**: `Chainsmoker/Ambxst`
**Branch con tus patches**: `feat/always-show-player`

### Estado normal de remotes

```
$ cd ~/Repos/Ambxst && git remote -v
origin    https://github.com/Chainsmoker/Ambxst.git   (fetch)
origin    https://github.com/Chainsmoker/Ambxst.git   (push)
upstream  https://github.com/Axenide/Ambxst.git       (fetch)
upstream  https://github.com/Axenide/Ambxst.git       (push)
```

### Traer cambios de upstream a tu fork

```bash
cd ~/Repos/Ambxst

# Asegurate estar en la branch correcta
git checkout feat/always-show-player

# Bajar lo nuevo de Axenide
git fetch upstream

# Rebase tus commits encima de upstream/main
git rebase upstream/main
```

Si hay **conflictos durante el rebase**, resolvé archivo por archivo:

```bash
$EDITOR archivo-conflicto
git add archivo-conflicto
git rebase --continue
```

Si te perdés:

```bash
git rebase --abort   # vuelve al estado pre-rebase, sin cambios
```

### Pushear el rebase a tu fork

```bash
# Después del rebase, force-push (porque la historia cambió)
git push --force-with-lease origin feat/always-show-player
```

`--force-with-lease` es más seguro que `--force` — falla si alguien más pusheó al remoto mientras vos rebaseabas.

### Verificar que los patches sigan ahí

```bash
git log --oneline upstream/main..HEAD
```

Deberías ver los commits de tus features:

- `feat(controlpanel)`
- `feat(chatpanel)`
- `feat(GtkGenerator): @import gtk-extra.css`
- `fix(bar/workspaces): Button → Item`
- `fix(overview): no warpear cursor`
- `feat(compactplayer): mostrar reproductor siempre`
- etc.

### Si querés mergear en lugar de rebase

```bash
git checkout feat/always-show-player
git merge upstream/main
# resolver conflictos, commit
git push origin feat/always-show-player    # sin --force
```

Merge mantiene la historia completa (más commits, más mess), rebase la reescribe (más limpio pero requiere force-push). **Default: rebase**.

---

## 3. axctl fork

**Upstream**: `Axenide/axctl`
**Tu fork**: `Chainsmoker/axctl`
**Branch con tus patches**: `fix/hyprland-dispatcher`

### Estado normal

```bash
$ cd ~/Repos/axctl && git remote -v
origin    https://github.com/Chainsmoker/axctl.git    (fetch/push)
upstream  https://github.com/Axenide/axctl.git        (fetch/push)
```

### Sincronizar y rebuild

```bash
cd ~/Repos/axctl
git checkout fix/hyprland-dispatcher
git fetch upstream
git rebase upstream/main

# Re-compilar
go build -o bin/axctl .

# Reinstalar el binary
sudo install -m 0755 bin/axctl /usr/local/bin/axctl

# Re-arrancar Ambxst para que use el nuevo binary
pkill -x qs
pkill -x axctl
ambxst &
```

### Si upstream mergea tu PR (Axenide/axctl#5)

Si Axenide mergea el fix de `hl.dsp.*` upstream, tu branch `fix/hyprland-dispatcher` se vuelve redundante. Podés:

1. **Borrar tu fork patcheado** y volver a usar upstream:

```bash
cd ~/Repos/axctl
git checkout main
git pull upstream main
git push origin main
git branch -D fix/hyprland-dispatcher
git push origin --delete fix/hyprland-dispatcher
```

2. **Editar `install-ambxst.sh`** para que clone upstream en lugar de tu fork:

```bash
# En install-ambxst.sh, cambiar:
AXCTL_REPO_URL="${AXCTL_REPO_URL:-https://github.com/Axenide/axctl.git}"
AXCTL_BRANCH="${AXCTL_BRANCH:-main}"
```

---

## Troubleshooting

### "axctl workspace switch reporta Success pero no cambia workspace"

axctl upstream usa sintaxis Lua que mainline Hyprland rechaza. Tu fork lo arregla. Verificar:

```bash
strings $(which axctl) | grep -c "hl.dsp.focus"
# 0 → tenés el binary patcheado (bien)
# 1+ → tenés el binary upstream (mal) — reinstalar de tu fork
```

### "Los widgets de Ambxst dejan de responder a clicks"

Probable conflicto de daemons. axctl puede tener un daemon stale + Ambxst spawneando otro.

```bash
pkill -x axctl
rm -f /tmp/axctl-*.sock
pkill -x qs
ambxst &
# Ambxst spawneará el daemon limpio
```

Y verificá que `hyprland.conf` NO tenga `exec-once = axctl daemon` (Ambxst lo spawnea solo).

### "Los estilos translúcidos de Nautilus desaparecen al cambiar wallpaper"

Tu fork de Ambxst tiene un patch en `GtkGenerator.qml` que pre-pende `@import gtk-extra.css`. Si el patch no se aplicó:

```bash
head -3 ~/.config/gtk-4.0/gtk.css
# debe aparecer:
#   @import url("file:///home/.../gtk-4.0/gtk-extra.css");
```

Si no aparece, tu Ambxst no es el del fork. Re-instalar:

```bash
bash ~/dotfiles/install-ambxst.sh
```

### "Los folders de Papirus no cambian de color al cambiar wallpaper"

Verificar que el sudoers NOPASSWD esté configurado:

```bash
sudo -n papirus-folders -C green && echo "✓ funciona" || echo "✗ falta sudoers"
```

Si falla:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/papirus-folders" \
    | sudo tee /etc/sudoers.d/papirus-folders
sudo chmod 0440 /etc/sudoers.d/papirus-folders
```

### "Quiero deshacer todos los patches y volver a upstream limpio"

```bash
# Ambxst
cd ~/Repos/Ambxst
git checkout main
git pull upstream main
git push origin main

# axctl
cd ~/Repos/axctl
git checkout main
git pull upstream main
sudo install -m 0755 <(curl -sL https://get.axeni.de/axctl 2>/dev/null | sh) /usr/local/bin/axctl

# Reiniciar Ambxst con upstream
pkill -x qs
ambxst &
```

⚠ Vas a perder TODOS los UX patches (side notch, chat panel, fixes de cursor warp, button → item, etc.).

---

## CHECKLIST POST-UPDATE

Después de cualquier rebase/merge de upstream, verificar:

- [ ] `hyprctl reload && hyprctl configerrors` retorna `ok` y vacío
- [ ] `axctl workspace switch 5` cambia de workspace real (no solo dice "Success")
- [ ] Click en workspace dots del bar cambia workspace
- [ ] Hover sobre ventana en overview NO teleporta el cursor
- [ ] `wall <imagen>` regenera paleta + recolorea folders Papirus
- [ ] `head -3 ~/.config/gtk-4.0/gtk.css` muestra `@import gtk-extra.css`
- [ ] Side notch en borde izquierdo aparece en hover
- [ ] Click en icono robot del side notch abre el ChatPanel
