#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Super+Space — unified running-system switcher
#   • every open window      → focus it
#   • every Docker container → follow its logs in a terminal
# Toggle: pressing the key again while open closes the menu.
# ─────────────────────────────────────────────────────────────

set -uo pipefail

# Toggle off if the menu is already open
if pgrep -x wofi >/dev/null 2>&1; then
    pkill -x wofi
    exit 0
fi

declare -A ACTIONS
entries=()

add() { entries+=("$2"); ACTIONS["$2"]="$1"; }

# ── Open windows ─────────────────────────────────────────────
while IFS=$'\t' read -r addr title cls; do
    [ -z "${addr:-}" ] && continue
    label="󰖯  ${title:-$cls}"
    add "window:${addr}" "$label"
done < <(python3 - <<'PY'
import json, subprocess
try:
    clients = json.loads(subprocess.run(
        ["hyprctl", "clients", "-j"], capture_output=True, text=True).stdout)
except Exception:
    clients = []
for c in clients:
    if not c.get("mapped") or c.get("hidden"):
        continue
    print("\t".join([
        c.get("address", ""),
        (c.get("title") or "").replace("\t", " "),
        (c.get("class") or "").replace("\t", " "),
    ]))
PY
)

# ── Docker containers ────────────────────────────────────────
while IFS=$'\t' read -r name status; do
    [ -z "${name:-}" ] && continue
    label="󰡨  ${name}   ·  ${status}"
    add "docker:${name}" "$label"
done < <(docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null)

# ── Nothing running? ─────────────────────────────────────────
if [ ${#entries[@]} -eq 0 ]; then
    notify-send "System switcher" "No running windows or containers" 2>/dev/null
    exit 0
fi

# ── Menu ─────────────────────────────────────────────────────
choice=$(printf '%s\n' "${entries[@]}" | wofi --dmenu \
    --prompt "Running apps & containers" \
    --insensitive \
    --matching fuzzy \
    --width 1000 \
    --height 560 \
    --define hide_scroll=false \
    --cache-file /dev/null)

[ -z "${choice:-}" ] && exit 0

action="${ACTIONS[$choice]:-}"
[ -z "$action" ] && exit 0

case "$action" in
    window:*)
        addr="${action#window:}"
        hyprctl dispatch "hl.dsp.focus({ window = \"address:${addr}\" })" >/dev/null
        ;;
    docker:*)
        name="${action#docker:}"
        kitty --title="docker: ${name}" -e docker logs -f --tail=200 "$name" &
        ;;
esac
