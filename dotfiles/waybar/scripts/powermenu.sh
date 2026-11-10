#!/usr/bin/env bash
# Minimal power menu for Waybar (rofi based)
options=(
    "  Lock"
    "  Logout"
    "  Suspend"
    "  Reboot"
    "  Shutdown"
)

chosen=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Power" -theme-str '
    window   { width: 220px; background-color: #0b0b0d; border: 1px solid #2a2a2e; border-radius: 14px; padding: 8px; }
    listview { lines: 5; margin: 4px 0 0 0; }
    element  { border-radius: 8px; padding: 8px 12px; }
    element selected { background-color: #f2f2f2; text-color: #0b0b0d; }
')

case "$chosen" in
    *Lock)     hyprlock & ;;
    *Logout)   hyprctl dispatch exit ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
