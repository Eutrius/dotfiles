#!/usr/bin/env bash
# Control speaker/mic volume with on-screen notifications
# Usage: volume.sh [--get | --inc | --dec | --toggle | --toggle-mic |
#                   --get-icon | --get-mic-icon | --mic-inc | --mic-dec]

iDIR="$HOME/.config/swaync/icons"

# --- Speaker ---
get_volume() {
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/volume-mute.png"
    elif [[ "${current%\%}" -le 30 ]]; then
        echo "$iDIR/volume-low.png"
    elif [[ "${current%\%}" -le 60 ]]; then
        echo "$iDIR/volume-mid.png"
    else
        echo "$iDIR/volume-high.png"
    fi
}

notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: $(get_volume)"
    fi
}

inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -i 5 --allow-boost --set-limit 150 && notify_user
    fi
}

dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -d 5 && notify_user
    fi
}

toggle_mute() {
    if [ "$(pamixer --get-mute)" == "false" ]; then
        pamixer -m && notify-send -e -u low -i "$iDIR/volume-mute.png" "Volume Switched OFF"
    elif [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify-send -e -u low -i "$(get_icon)" "Volume Switched ON"
    fi
}

# --- Microphone ---
toggle_mic() {
    if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
        pamixer --default-source -m && notify-send -e -u low -i "$iDIR/microphone-mute.png" "Microphone Switched OFF"
    elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer -u --default-source u && notify-send -e -u low -i "$iDIR/microphone.png" "Microphone Switched ON"
    fi
}

get_mic_icon() {
    current=$(pamixer --default-source --get-volume)
    if [[ "$current" -eq "0" ]]; then
        echo "$iDIR/microphone-mute.png"
    else
        echo "$iDIR/microphone.png"
    fi
}

get_mic_volume() {
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_mic_icon)
    notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon" "Mic-Level: $volume"
}

inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -i 5 && notify_mic_user
    fi
}

dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -d 5 && notify_mic_user
    fi
}

case "$1" in
    "--get")          get_volume ;;
    "--inc")          inc_volume ;;
    "--dec")          dec_volume ;;
    "--toggle")       toggle_mute ;;
    "--toggle-mic")   toggle_mic ;;
    "--get-icon")     get_icon ;;
    "--get-mic-icon") get_mic_icon ;;
    "--mic-inc")      inc_mic_volume ;;
    "--mic-dec")      dec_mic_volume ;;
    *)                get_volume ;;
esac
