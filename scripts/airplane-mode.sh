#!/usr/bin/env bash
# Toggle airplane mode: Wi-Fi/WWAN via NetworkManager + Bluetooth via bluetoothctl

if [ "$(nmcli radio wifi)" = "enabled" ]; then
    nmcli radio all off
    bluetoothctl power off
    notify-send -e -u low "Airplane Mode" "Enabled — Wi-Fi & Bluetooth off"
else
    nmcli radio all on
    bluetoothctl power on
    notify-send -e -u low "Airplane Mode" "Disabled — Wi-Fi & Bluetooth on"
fi
