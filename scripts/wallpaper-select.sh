#!/usr/bin/env bash
# Wallpaper picker (SUPER + X): choose a wallpaper via rofi and apply it with swww

wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# swww transition settings
FPS=60
TYPE="any"
DURATION=2
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

if pidof swaybg >/dev/null; then
    pkill swaybg
fi

# Collect image files (null-delimited to handle spaces in filenames)
mapfile -d '' PICS < <(find "${wallDIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)

rofi_command="rofi -i -show -dmenu -config ~/.config/rofi/config-wallpaper.rasi"

# Build the rofi menu (sorted, with thumbnails; .gif shown by name only)
menu() {
    IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))

    for pic_path in "${sorted_options[@]}"; do
        pic_name=$(basename "$pic_path")

        if [[ ! "$pic_name" =~ \.gif$ ]]; then
            printf "%s\x00icon\x1f%s\n" "$(echo "$pic_name" | cut -d. -f1)" "$pic_path"
        else
            printf "%s\n" "$pic_name"
        fi
    done
}

awww query || awww-daemon --format argb

main() {
    choice=$(menu | $rofi_command)
    choice=$(echo "$choice" | xargs)

    if [[ -z "$choice" ]]; then
        echo "No choice selected. Exiting."
        exit 0
    fi

    pic_index=-1
    for i in "${!PICS[@]}"; do
        filename=$(basename "${PICS[$i]}")
        if [[ "$filename" == "$choice"* ]]; then
            pic_index=$i
            break
        fi
    done

    if [[ $pic_index -ne -1 ]]; then
        awww img -o "$focused_monitor" "${PICS[$pic_index]}" $SWWW_PARAMS
        echo "${PICS[$pic_index]}" > "$HOME/.cache/swww/$focused_monitor"
    else
        echo "Image not found."
        exit 1
    fi
}

if pidof rofi >/dev/null; then
    pkill rofi
    sleep 1
fi

main

sleep 0.5
"$SCRIPTSDIR/wallust-swww.sh"

sleep 0.2
"$SCRIPTSDIR/refresh.sh"
