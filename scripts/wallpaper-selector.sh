#!/bin/bash

# ============================================================================
# WOFI WALLPAPER SELECTOR
# ============================================================================
# Interactive wallpaper selector with preview support
# ============================================================================

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
THEME_ENGINE="$HOME/.config/hypr/scripts/theme-engine.sh"
CACHE_DIR="$HOME/.cache/wallpaper-selector"

mkdir -p "$CACHE_DIR"

# Generate wallpaper list with thumbnails
generate_list() {
    local list=""
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$wallpaper" && "$wallpaper" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            local basename=$(basename "$wallpaper")
            local name="${basename%.*}"
            
            # Create thumbnail if it doesn't exist
            local thumb="$CACHE_DIR/${name}_thumb.jpg"
            if [ ! -f "$thumb" ]; then
                if command -v convert &> /dev/null; then
                    convert "$wallpaper" -resize 200x200^ -gravity center -extent 200x200 "$thumb" 2>/dev/null
                fi
            fi
            
            list+="$name\n"
        fi
    done
    echo -e "$list"
}

# Show wofi selector
selected=$(generate_list | wofi \
    --dmenu \
    --prompt "Select Wallpaper" \
    --width 600 \
    --height 400)

if [ -n "$selected" ]; then
    # Find the full path of selected wallpaper
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ "$(basename "$wallpaper")" =~ ^"$selected"\. ]]; then
            "$THEME_ENGINE" apply "$wallpaper"
            notify-send "Wallpaper Changed" "Applied: $selected" -i "$wallpaper"
            exit 0
        fi
    done
fi
