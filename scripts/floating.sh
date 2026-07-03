#!/usr/bin/env bash
# Toggle floating on the active window; when floating, resize to 1500x900 and center

is_floating=$(hyprctl activewindow | grep "floating" | awk '{print $2}')
if [[ "$is_floating" -eq 1 ]]; then
    hyprctl dispatch togglefloating
else
    hyprctl --batch "dispatch togglefloating ; dispatch resizeactive exact 1500 900 ; dispatch centerwindow 1"
fi
