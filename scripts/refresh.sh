#!/usr/bin/env bash
# Restart waybar and swaync (used to reload after theme/config changes)

# Kill running instances
_ps=(waybar rofi swaync)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

sleep 1
waybar &

sleep 0.5
swaync >/dev/null 2>&1 &

exit 0
