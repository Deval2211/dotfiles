#!/bin/bash
# Rofi Wallpaper Selector

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
THEME_ENGINE="$HOME/.config/hypr/scripts/theme-engine.sh"
CACHE_DIR="$HOME/.cache/wallpaper-selector"

mkdir -p "$CACHE_DIR"

generate_list() {
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$wallpaper" && "$wallpaper" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            local name
            name=$(basename "$wallpaper")
            echo "${name%.*}"
        fi
    done
}

selected=$(generate_list | rofi -dmenu -p "Wallpaper" -i)

if [[ -n "$selected" ]]; then
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ "$(basename "$wallpaper")" =~ ^"$selected"\. ]]; then
            "$THEME_ENGINE" apply "$wallpaper"
            notify-send "Wallpaper Changed" "Applied: $selected"
            exit 0
        fi
    done
fi
