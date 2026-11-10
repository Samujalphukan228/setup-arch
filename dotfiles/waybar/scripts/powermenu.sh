#!/usr/bin/env bash
# Minimal power menu for Waybar (wofi based)
options=(
    "Lock"
    "Logout"
    "Suspend"
    "Reboot"
    "Shutdown"
)

chosen=$(printf '%s\n' "${options[@]}" | wofi --dmenu --insensitive \
    --no-custom-entry --cache-file /dev/null \
    --width 240 --height 320 --prompt "Power")

case "$chosen" in
    *Lock)     hyprlock & ;;
    *Logout)   hyprctl dispatch "hl.dsp.exit()" ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
