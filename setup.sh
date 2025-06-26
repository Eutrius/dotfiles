#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/test"
AVAILABLE_CONFIGS=()

echo "🔍 Checking for submodules..."
if [ ! -d "$DOTFILES_DIR/.git/modules" ] || ! git submodule status | grep -qv ' '; then
    echo "📦 Initializing and updating submodules..."
    git submodule update --init --recursive
else
    echo "✅ Submodules already initialized."
fi

for dir in "$DOTFILES_DIR"/*; do
    [ -d "$dir" ] && AVAILABLE_CONFIGS+=("$(basename "$dir")")
done

is_linked() {
    local config_name="$1"
    [ -L "$CONFIG_DIR/$config_name" ] && return 0 || return 1
}

show_menu() {
    echo "🛠️  Available configs:"
    for i in "${!AVAILABLE_CONFIGS[@]}"; do
        local idx=$((i + 1))
        local config="${AVAILABLE_CONFIGS[$i]}"
        if is_linked "$config"; then
            echo "$idx) $config (✅ linked)"
        else
            echo "$idx) $config"
        fi
    done
    echo "$(( ${#AVAILABLE_CONFIGS[@]} + 1 ))) all"
}

already_installed=()
while true; do
    show_menu
    read -rp "Enter numbers of configs to install (e.g., 13), or press Enter to quit: " selection

    if [ -z "$selection" ]; then
        echo "👋 Exiting."
        break
    fi

    declare -A installed_now=()

    for ((i = 0; i < ${#selection}; i++)); do
        idx="${selection:$i:1}"
        if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
            echo "❌ Invalid input: '$idx' is not a number."
            continue
        fi

        if [ "$idx" -eq "$(( ${#AVAILABLE_CONFIGS[@]} + 1 ))" ]; then
            # Handle "all"
            for config in "${AVAILABLE_CONFIGS[@]}"; do
                installed_now["$config"]=1
            done
            break
        fi

        config_idx=$((idx - 1))
        if [ "$config_idx" -ge 0 ] && [ "$config_idx" -lt "${#AVAILABLE_CONFIGS[@]}" ]; then
            config="${AVAILABLE_CONFIGS[$config_idx]}"
            installed_now["$config"]=1
        else
            echo "⚠️  Skipping invalid index: $idx"
        fi
    done

    for config in "${!installed_now[@]}"; do
        target="$CONFIG_DIR/$config"
        source="$DOTFILES_DIR/$config"

        if is_linked "$config"; then
            echo "🔁 $config is already linked — skipping."
        elif [ -e "$target" ]; then
            echo "⚠️  $target exists and is not a symlink — skipping."
        else
            echo "🔗 Linking $config..."
            ln -s "$source" "$target"
            echo "✅ Linked $config → $target"
        fi
    done
done
