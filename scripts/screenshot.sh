#!/usr/bin/env bash
# Screenshot helper (grim/slurp/swappy) with notifications
# Usage: screenshot.sh [--now | --in5 | --in10 | --win | --area | --active | --swappy]

iDIR="$HOME/.config/swaync/icons"
notify_cmd_shot="notify-send -h string:x-canonical-private-synchronous:shot-notify -u low -i ${iDIR}/picture.png"

time=$(date "+%d-%b_%H-%M-%S")
dir="$(xdg-user-dir)/Pictures/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

# Notify whether the screenshot was saved
notify_view() {
    if [[ "$1" == "active" ]]; then
        if [[ -e "${active_window_path}" ]]; then
            ${notify_cmd_shot} "Screenshot of '${active_window_class}' Saved."
        else
            ${notify_cmd_shot} "Screenshot of '${active_window_class}' not Saved"
        fi
    elif [[ "$1" == "swappy" ]]; then
        ${notify_cmd_shot} "Screenshot Captured."
    else
        local check_file="$dir/$file"
        if [[ -e "$check_file" ]]; then
            ${notify_cmd_shot} "Screenshot Saved."
        else
            ${notify_cmd_shot} "Screenshot NOT Saved."
        fi
    fi
}

# Countdown notification before a timed shot
countdown() {
    for sec in $(seq $1 -1 1); do
        notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$iDIR"/timer.png "Taking shot in : $sec"
        sleep 1
    done
}

shotnow() {
    cd ${dir} && grim - | tee "$file" | wl-copy
    sleep 2
    notify_view
}

shot5() {
    countdown '5'
    sleep 1 && cd ${dir} && grim - | tee "$file" | wl-copy
    sleep 1
    notify_view
}

shot10() {
    countdown '10'
    sleep 1 && cd ${dir} && grim - | tee "$file" | wl-copy
    notify_view
}

shotwin() {
    w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
    w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)
    cd ${dir} && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
    notify_view
}

shotarea() {
    tmpfile=$(mktemp)
    grim -g "$(slurp)" - >"$tmpfile"
    if [[ -s "$tmpfile" ]]; then
        wl-copy <"$tmpfile"
        mv "$tmpfile" "$dir/$file"
    fi
    notify_view
}

shotactive() {
    active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
    active_window_file="Screenshot_${time}_${active_window_class}.png"
    active_window_path="${dir}/${active_window_file}"

    hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${active_window_path}"
    sleep 1
    notify_view "active"
}

shotswappy() {
    tmpfile=$(mktemp)
    grim -g "$(slurp)" - >"$tmpfile" && notify_view "swappy"
    swappy -f - <"$tmpfile"
    rm "$tmpfile"
}

if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

case "$1" in
    "--now")    shotnow ;;
    "--in5")    shot5 ;;
    "--in10")   shot10 ;;
    "--win")    shotwin ;;
    "--area")   shotarea ;;
    "--active") shotactive ;;
    "--swappy") shotswappy ;;
    *)          echo -e "Available Options : --now --in5 --in10 --win --area --active --swappy" ;;
esac

exit 0
