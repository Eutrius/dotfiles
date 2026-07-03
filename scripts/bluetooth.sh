#!/usr/bin/env bash
# Toggle Bluetooth power on/off

status=$(bluetoothctl show | grep "Powered: yes")
if [ -n "$status" ]; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
