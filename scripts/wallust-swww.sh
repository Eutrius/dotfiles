#!/usr/bin/env bash
# Sync the current wallpaper into rofi/hyprlock assets for the focused monitor

cache_dir="$HOME/.cache/swww/"
current_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
cache_file="$cache_dir$current_monitor"

if [ -f "$cache_file" ]; then
    wallpaper_path=$(cat "$cache_file")
    ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"
    magick convert -resize 300x300! "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_square"
    cp "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fi
