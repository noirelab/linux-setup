#!/usr/bin/env bash
# Reconnect a paired JBL Go 5 and restore its PipeWire audio sink.
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: ./fix-bluetooth-audio.sh [BLUETOOTH-MAC]

Without a MAC address, the script finds the paired device whose name contains
"JBL Go 5". If more than one matches, pass the desired MAC address explicitly.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

for cmd in bluetoothctl wpctl systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if (($# > 1)); then
    usage >&2
    exit 2
fi

if (($# == 1)); then
    device_mac="$1"
else
    mapfile -t matches < <(bluetoothctl devices Paired | awk 'tolower($0) ~ /jbl go 5/ {print $2}')
    case "${#matches[@]}" in
        0) die 'No paired device named JBL Go 5 found. Pair it first or pass its MAC address.' ;;
        1) device_mac="${matches[0]}" ;;
        *) printf 'More than one paired JBL Go 5 found:\n' >&2; printf '  %s\n' "${matches[@]}" >&2; die 'Pass the desired MAC address.' ;;
    esac
fi

[[ "$device_mac" =~ ^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$ ]] || die "Invalid Bluetooth MAC address: $device_mac"

printf 'JBL device: %s\n' "$device_mac"
device_info="$(bluetoothctl info "$device_mac")" || die 'Could not read device information. Check that Bluetooth is running and the device is paired.'
printf '%s\n' "$device_info"
device_alias="$(sed -n 's/^[[:space:]]*Alias: //p' <<< "$device_info" | head -n 1)"
[[ -n "$device_alias" ]] || device_alias='JBL Go 5'

reconnect_device() {
    bluetoothctl disconnect "$device_mac" >/dev/null 2>&1 || true
    sleep 2
    bluetoothctl connect "$device_mac" || return 1
}

find_sink_id() {
    wpctl status | awk -v needle="$device_alias" '
        /Sinks:/ { in_sinks = 1; next }
        /Sources:/ { in_sinks = 0 }
        in_sinks && index(tolower($0), tolower(needle)) {
            line = $0
            sub(/^[^0-9]*/, "", line)
            sub(/\..*$/, "", line)
            print line
            exit
        }
    '
}

wait_for_sink() {
    local attempt
    for attempt in {1..10}; do
        sink_id="$(find_sink_id)"
        [[ -n "$sink_id" ]] && return 0
        sleep 1
    done
    return 1
}

printf '\nDisconnecting and reconnecting to renegotiate the audio profile...\n'
reconnect_device || die 'Bluetooth connection failed. Check that the speaker is on and not connected to another device.'

if ! wait_for_sink; then
    printf '\nNo JBL audio sink appeared. Restarting WirePlumber and reconnecting once...\n'
    systemctl --user restart wireplumber || die 'Could not restart the user WirePlumber service.'
    sleep 2
    reconnect_device || die 'Bluetooth reconnection failed after restarting WirePlumber.'
    wait_for_sink || {
        printf '\nPipeWire sinks after retry:\n' >&2
        wpctl status >&2 || true
        printf '\nRecent WirePlumber log:\n' >&2
        journalctl --user -u wireplumber -b --no-pager -n 40 >&2 || true
        die 'The JBL connected, but PipeWire did not create its audio sink.'
    }
fi

wpctl set-default "$sink_id"
printf '\nJBL audio sink %s is now the default output.\n' "$sink_id"
wpctl status
