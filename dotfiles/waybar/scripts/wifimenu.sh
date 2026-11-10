#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  Wi-Fi / network panel for Waybar  ·  rofi UI styled like the bar
#  Usage: wifimenu.sh          → open the menu
#         wifimenu.sh --toggle → toggle Wi-Fi radio on/off
# ─────────────────────────────────────────────────────────────────

set -uo pipefail

# ── Theme (matches ~/.config/waybar/style.css) ───────────────────
THEME='
window {
    width: 400px;
    background-color: #0b0b0d;
    border: 1px solid;
    border-color: #2a2a2e;
    border-radius: 14px;
    padding: 12px;
}
mainbox { spacing: 6px; }
inputbar {
    children: [ "prompt", "entry" ];
    background-color: #17171a;
    border-radius: 9px;
    padding: 8px 12px;
    margin: 0 0 6px 0;
}
prompt { text-color: #8a8a8f; margin: 0 8px 0 0; }
entry { placeholder: "Search networks"; placeholder-color: #6d6d73; text-color: #f2f2f2; }
listview { lines: 12; columns: 1; spacing: 2px; scrollbar: false; }
element { border-radius: 9px; padding: 9px 12px; }
element normal.normal    { background-color: transparent; text-color: #cfcfd4; }
element alternate.normal { background-color: transparent; text-color: #cfcfd4; }
element selected.normal  { background-color: #f2f2f2; text-color: #0b0b0d; }
message { border-radius: 9px; background-color: #17171a; padding: 10px 12px; margin: 0 0 6px 0; }
textbox { text-color: #cfcfd4; }
'

PASS_THEME='
window {
    width: 340px;
    background-color: #0b0b0d;
    border: 1px solid;
    border-color: #2a2a2e;
    border-radius: 14px;
    padding: 12px;
}
mainbox { spacing: 6px; }
inputbar { background-color: #17171a; border-radius: 9px; padding: 8px 12px; }
prompt { text-color: #8a8a8f; margin: 0 8px 0 0; }
entry { placeholder: "Password"; placeholder-color: #6d6d73; text-color: #f2f2f2; }
'

# Read-only details view: no row highlight, no filtering hint
DETAILS_EXTRA='
element selected.normal { background-color: transparent; text-color: #cfcfd4; }
entry { placeholder: "Press Esc to close"; placeholder-color: #6d6d73; }
'

rofi_menu() { rofi -dmenu -i -no-custom -theme-str "$THEME" "$@"; }
notify()    { notify-send -a "Network" -i network-wireless "$1" "${2:-}"; }

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
    printf '%s\n' "$details" | rofi -dmenu -no-custom -p "Network details" \
        -theme-str "$THEME$DETAILS_EXTRA" >/dev/null
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
        pass=$(rofi -dmenu -password -p "Password · $ssid" -theme-str "$PASS_THEME") || return
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
    local -a names=() labels=() acts=()
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
        acts+=("up:$n")
    done
    labels+=("󰅖  Forget a network…")
    acts+=("forget")

    local choice act
    choice=$(printf '%s\n' "${labels[@]}" | rofi_menu -p "Saved networks" -format i) || return
    [[ -z $choice ]] && return
    act=${acts[$choice]}

    case $act in
        up:*)
            local ssid=${act#up:} out
            out=$(nmcli --wait 20 connection up id "$ssid" 2>&1) \
                || { notify-send -u critical -a "Network" "Could not connect to $ssid" "$out"; return; }
            notify "Connected" "$ssid"
            ;;
        forget)
            local idx
            choice=$(printf '%s\n' "${labels[@]:0:${#names[@]}}" | rofi_menu -p "Forget network" -format i) || return
            [[ -z $choice ]] && return
            local victim=${names[$choice]}
            local confirm
            confirm=$(printf 'Cancel\nDelete' | rofi_menu -p "Delete “$victim”?") || return
            if [[ $confirm == "Delete" ]]; then
                nmcli connection delete id "$victim" >/dev/null 2>&1 \
                    && notify "Forgotten" "$victim" \
                    || notify-send -u critical -a "Network" "Could not forget $victim"
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
    local -a labels=() acts=()

    if [[ $(wifi_state) != "enabled" ]]; then
        labels+=("󰖪  Turn Wi-Fi on")
        acts+=("wifi-on")
        labels+=("󰒓  Network settings")
        acts+=("settings")
        labels+=("󰙨  Connection details")
        acts+=("details")
        labels+=("󰅖  Close")
        acts+=("quit")
    else
        # Visible access points
        local -a ap_ssid=() ap_sec=() ap_sig=() ap_active=()
        local inuse ssid sig sec
        while IFS=: read -r inuse ssid sig sec; do
            [[ -z $ssid ]] && continue
            ap_ssid+=("$ssid")
            ap_sec+=("$sec")
            ap_sig+=("$sig")
            ap_active+=("$inuse")
        done < <(nmcli -t --escape no -f IN-USE,SSID,SIGNAL,SECURITY \
                    device wifi list --rescan no ifname "$iface" 2>/dev/null)

        if (( ${#ap_ssid[@]} == 0 )); then
            labels+=("󰤯  No networks found — scan?")
            acts+=("rescan")
        else
            local i mark lock
            for i in "${!ap_ssid[@]}"; do
                mark="  "
                [[ ${ap_active[$i]} == "*" ]] && mark="󰄬 "
                lock=""
                [[ -n ${ap_sec[$i]} ]] && lock="  󰌾"
                labels+=("${mark}$(signal_icon "${ap_sig[$i]}")  ${ap_ssid[$i]}   ${ap_sig[$i]}%${lock}")
                acts+=("ap:$i")
            done
        fi

        labels+=("󰏫  Scan for networks")
        acts+=("rescan")
        labels+=("󰖩  Turn Wi-Fi off")
        acts+=("wifi-off")
        [[ -n $(current_ssid) ]] && { labels+=("󰅖  Disconnect"); acts+=("disconnect"); }
        labels+=("󰒲  Saved networks…")
        acts+=("saved")
        labels+=("󰙨  Connection details")
        acts+=("details")
        labels+=("󰒓  Network settings")
        acts+=("settings")
    fi

    local prompt="Wi-Fi"
    [[ $(wifi_state) == "enabled" ]] && prompt="Wi-Fi · ${iface}"

    local choice act
    choice=$(printf '%s\n' "${labels[@]}" | rofi_menu -p "$prompt" -format i) || exit 0
    [[ -z $choice ]] && exit 0
    act=${acts[$choice]}

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
