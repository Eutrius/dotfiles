#!/usr/bin/env bash
# Toggle between the master and dwindle layouts

notif="$HOME/.config/swaync/images/bell.png"

layout=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case "$layout" in
    "master")
        hyprctl keyword general:layout dwindle
        notify-send -e -u low -i "$notif" "Dwindle Layout"
        ;;
    "dwindle")
        hyprctl keyword general:layout master
        notify-send -e -u low -i "$notif" "Master Layout"
        ;;
    *) ;;
esac
