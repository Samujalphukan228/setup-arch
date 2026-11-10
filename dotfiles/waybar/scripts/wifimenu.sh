#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  Wi-Fi / network panel for Waybar  ·  Wofi UI styled like the bar
#  Usage: wifimenu.sh          → open the menu
#         wifimenu.sh --toggle → toggle Wi-Fi radio on/off
#         wifimenu.sh --details, --saved
# ─────────────────────────────────────────────────────────────────

set -uo pipefail

MENU_WIDTH=460
MENU_HEIGHT=520

wofi_menu() {
    wofi --dmenu --insensitive --no-custom-entry --cache-file /dev/null \
        --width "$MENU_WIDTH" --height "$MENU_HEIGHT" "$@"
}
notify() { notify-send -a "Network" -i network-wireless "$1" "${2:-}"; }

# ── Helpers ───────────────────────────────────────────────────────
iface=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}')
[[ -z ${iface:-} ]] && iface="wlo1"

wifi_state() { nmcli radio wifi 2>/dev/null || echo "disabled"; }

signal_icon() {
    local s=${1:-0}
    if   (( s >= 80 )); then echo "󰤨"
    elif (( s >= 60 )); then echo "󰤥"
    elif (( s >= 40 )); then echo "󰤢"
    elif (( s >= 20 )); then echo "󰤟"
    else                     echo "󰤯"
    fi
}

current_ssid() {
    nmcli -t -f GENERAL.CONNECTION device show "$iface" 2>/dev/null \
        | awk -F: '$2!="" && $2!="--"{print $2; exit}'
}

# ── Connection actions ────────────────────────────────────────────
show_details() {
    local details ssid
    ssid=$(nmcli -t -f ACTIVE,SSID device wifi list 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')
    details=$(nmcli -t --escape no -f \
        GENERAL.CONNECTION,GENERAL.STATE,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS \
        device show "$iface" 2>/dev/null |
        sed -e 's/^GENERAL.CONNECTION:/Connection: /' \
            -e 's/^GENERAL.STATE:/State: /' \
            -e 's/^IP4.ADDRESS\[[0-9]*\]:/IP: /' \
            -e 's/^IP4.GATEWAY:/Gateway: /' \
            -e 's/^IP4.DNS\[[0-9]*\]:/DNS: /')

    [[ -n $ssid ]] && details="SSID: $ssid"$'\n'"$details"
    [[ -z $details ]] && details="No connection information."
    printf '%s\n' "$details" | wofi --dmenu --insensitive --no-custom-entry \
        --cache-file /dev/null --width "$MENU_WIDTH" --height 420 \
        --prompt "Network details" >/dev/null
}

connect_ssid() {
    local ssid=$1 sec=$2 pass out

    if [[ "$(current_ssid)" == "$ssid" ]]; then
        show_details
        return
    fi

    if nmcli -t -f NAME connection show | grep -Fxq -- "$ssid"; then
        out=$(nmcli --wait 20 connection up id "$ssid" 2>&1) \
            || { notify-send -u critical -a "Network" "Could not connect to $ssid" "$out"; return; }
    elif [[ -n $sec ]]; then
        pass=$(wofi --dmenu --password --cache-file /dev/null \
            --width 360 --prompt "Password · $ssid") || return
        [[ -z $pass ]] && return
        out=$(nmcli --wait 20 device wifi connect "$ssid" password "$pass" 2>&1) \
            || { notify-send -u critical -a "Network" "Could not connect to $ssid" "$out"; return; }
    else
        out=$(nmcli --wait 20 device wifi connect "$ssid" 2>&1) \
            || { notify-send -u critical -a "Network" "Could not connect to $ssid" "$out"; return; }
    fi

    notify "Connected" "$ssid"
}

saved_menu() {
    local -a names=() labels=()
    local -A act_of=()

    while IFS=: read -r type name; do
        [[ $type == "802-11-wireless" ]] && names+=("$name")
    done < <(nmcli -t --escape no -f TYPE,NAME connection show 2>/dev/null)

    if (( ${#names[@]} == 0 )); then
        notify "Saved networks" "No saved Wi-Fi networks."
        return
    fi

    local n
    for n in "${names[@]}"; do
        labels+=("󰖩  $n")
        act_of["󰖩  $n"]="up:$n"
    done
    labels+=("󰅖  Forget a network…")
    act_of["󰅖  Forget a network…"]="forget"

    local choice act
    choice=$(printf '%s\n' "${labels[@]}" | wofi_menu --prompt "Saved networks") || return
    [[ -z $choice ]] && return
    act=${act_of[$choice]:-}
    [[ -z $act ]] && return

    case $act in
        up:*)
            local ssid=${act#up:} out
            out=$(nmcli --wait 20 connection up id "$ssid" 2>&1) \
                || { notify-send -u critical -a "Network" "Could not connect to $ssid" "$out"; return; }
            notify "Connected" "$ssid"
            ;;
        forget)
            local -a forget_labels=()
            local -A victim_of=()
            for n in "${names[@]}"; do
                forget_labels+=("󰖩  $n")
                victim_of["󰖩  $n"]="$n"
            done
            choice=$(printf '%s\n' "${forget_labels[@]}" | wofi_menu --prompt "Forget network") || return
            [[ -z $choice ]] && return
            local victim=${victim_of[$choice]:-}
            [[ -z $victim ]] && return
            local confirm
            confirm=$(printf 'Cancel\nDelete' | wofi_menu --prompt "Delete \"$victim\"?") || return
            if [[ $confirm == "Delete" ]]; then
                if nmcli connection delete id "$victim" >/dev/null 2>&1; then
                    notify "Forgotten" "$victim"
                else
                    notify-send -u critical -a "Network" "Could not forget $victim"
                fi
            fi
            ;;
    esac
}

# ── Radio toggle shortcut ─────────────────────────────────────────
if [[ ${1:-} == "--toggle" ]]; then
    if [[ $(wifi_state) == "enabled" ]]; then
        nmcli radio wifi off && notify "Wi-Fi off"
    else
        nmcli radio wifi on && notify "Wi-Fi on"
    fi
    exit 0
fi

if [[ ${1:-} == "--details" ]]; then
    show_details
    exit 0
fi

if [[ ${1:-} == "--saved" ]]; then
    saved_menu
    exit 0
fi

# ── Main menu loop ────────────────────────────────────────────────
main_menu() {
    local -a labels=()
    local -A act_of=()
    local -a ap_ssid=() ap_sec=()

    if [[ $(wifi_state) != "enabled" ]]; then
        labels+=("󰖪  Turn Wi-Fi on");        act_of["󰖪  Turn Wi-Fi on"]="wifi-on"
        labels+=("󰒓  Network settings");     act_of["󰒓  Network settings"]="settings"
        labels+=("󰙨  Connection details");   act_of["󰙨  Connection details"]="details"
        labels+=("󰅖  Close");                act_of["󰅖  Close"]="quit"
    else
        local inuse ssid sig sec mark lock
        while IFS=: read -r inuse ssid sig sec; do
            [[ -z $ssid ]] && continue
            ap_ssid+=("$ssid")
            ap_sec+=("$sec")
            mark="  "
            [[ $inuse == "*" ]] && mark="󰄬 "
            lock=""
            [[ -n $sec ]] && lock="  󰌾"
            local label
            label="${mark}$(signal_icon "$sig")  ${ssid}   ${sig}%${lock}"
            labels+=("$label")
            act_of["$label"]="ap:${#ap_ssid[@]}-1"
        done < <(nmcli -t --escape no -f IN-USE,SSID,SIGNAL,SECURITY \
                    device wifi list --rescan no ifname "$iface" 2>/dev/null)

        if (( ${#ap_ssid[@]} == 0 )); then
            labels+=("󰤯  No networks found — scan?"); act_of["󰤯  No networks found — scan?"]="rescan"
        fi

        labels+=("󰏫  Scan for networks");      act_of["󰏫  Scan for networks"]="rescan"
        labels+=("󰖩  Turn Wi-Fi off");         act_of["󰖩  Turn Wi-Fi off"]="wifi-off"
        if [[ -n $(current_ssid) ]]; then
            labels+=("󰅖  Disconnect");         act_of["󰅖  Disconnect"]="disconnect"
        fi
        labels+=("󰒲  Saved networks…");        act_of["󰒲  Saved networks…"]="saved"
        labels+=("󰙨  Connection details");     act_of["󰙨  Connection details"]="details"
        labels+=("󰒓  Network settings");      act_of["󰒓  Network settings"]="settings"
    fi

    local prompt="Wi-Fi"
    [[ $(wifi_state) == "enabled" ]] && prompt="Wi-Fi · ${iface}"

    local choice act
    choice=$(printf '%s\n' "${labels[@]}" | wofi_menu --prompt "$prompt") || exit 0
    [[ -z $choice ]] && exit 0
    act=${act_of[$choice]:-}
    [[ -z $act ]] && exit 0

    case $act in
        ap:*)
            local idx=${act#ap:}
            connect_ssid "${ap_ssid[$idx]}" "${ap_sec[$idx]}"
            exit 0
            ;;
        rescan)
            nmcli device wifi rescan ifname "$iface" >/dev/null 2>&1
            sleep 2
            main_menu
            ;;
        wifi-on)
            nmcli radio wifi on >/dev/null 2>&1
            sleep 2
            notify "Wi-Fi on"
            main_menu
            ;;
        wifi-off)
            nmcli radio wifi off >/dev/null 2>&1
            notify "Wi-Fi off"
            exit 0
            ;;
        disconnect)
            nmcli device disconnect "$iface" >/dev/null 2>&1
            notify "Disconnected" "$(current_ssid)"
            exit 0
            ;;
        saved)    saved_menu ;;
        details)  show_details ;;
        settings)
            if command -v nm-connection-editor >/dev/null 2>&1; then
                setsid nm-connection-editor >/dev/null 2>&1 &
            else
                setsid nmtui >/dev/null 2>&1 &
            fi
            exit 0
            ;;
        quit)     exit 0 ;;
    esac
}

main_menu
