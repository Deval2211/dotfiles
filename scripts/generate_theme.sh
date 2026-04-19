#!/bin/bash
# Theme Generation Script - Matugen wrapper with validation

set -euo pipefail

CONFIG_DIR="$HOME/.config"
LOG_FILE="$HOME/.cache/theme-engine.log"
MATUGEN_CONFIG="$CONFIG_DIR/matugen/config.toml"

mkdir -p "$HOME/.cache"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[$(date +'%H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }

generate_theme() {
    local wallpaper="$1"
    local theme_dir="$2"

    if [[ ! -f "$wallpaper" ]]; then
        error "Wallpaper not found: $wallpaper"
        return 1
    fi

    log "Generating theme from: $(basename "$wallpaper")"

    # Extract dominant color using ImageMagick
    local source_color
    source_color=$(convert "$wallpaper" -resize 1x1\! -format "#%[hex:u]" info:- 2>/dev/null)

    if [[ -z "$source_color" || ! "$source_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        error "Failed to extract color from wallpaper"
        return 1
    fi

    log "Source color: $source_color"

    # Generate theme with matugen using extracted color
    if ! matugen color hex "$source_color" > /dev/null 2>&1; then
        error "Matugen generation failed"
        return 1
    fi

    # Validate outputs
    local errors=0

    if [[ -f "$CONFIG_DIR/hypr/colors.conf" ]]; then
        grep -q 'rgba(' "$CONFIG_DIR/hypr/colors.conf" && log "✓ Hyprland colors valid" || { error "✗ Hyprland colors invalid"; ((errors++)); }
    else
        error "✗ Hyprland colors not generated"; ((errors++))
    fi

    if [[ -f "$CONFIG_DIR/waybar/colors.css" ]]; then
        grep -q '@define-color' "$CONFIG_DIR/waybar/colors.css" && log "✓ Waybar colors valid" || { error "✗ Waybar colors invalid"; ((errors++)); }
    else
        error "✗ Waybar colors not generated"; ((errors++))
    fi

    if [[ -f "$CONFIG_DIR/kitty/colors.conf" ]]; then
        grep -q 'foreground' "$CONFIG_DIR/kitty/colors.conf" && log "✓ Kitty colors valid" || { error "✗ Kitty colors invalid"; ((errors++)); }
    else
        error "✗ Kitty colors not generated"; ((errors++))
    fi

    if [[ -f "$CONFIG_DIR/wofi/colors.css" ]]; then
        grep -q '@define-color' "$CONFIG_DIR/wofi/colors.css" && log "✓ Wofi colors valid" || { error "✗ Wofi colors invalid"; ((errors++)); }
    else
        error "✗ Wofi colors not generated"; ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        error "Validation failed with $errors errors"
        return 1
    fi

    log "✓ All configs validated"

    # Cache generated files
    cp "$CONFIG_DIR/hypr/colors.conf"   "$theme_dir/hyprland-colors.conf"
    cp "$CONFIG_DIR/kitty/colors.conf"  "$theme_dir/kitty-colors.conf"
    cp "$CONFIG_DIR/waybar/colors.css"  "$theme_dir/waybar-colors.css"
    cp "$CONFIG_DIR/wofi/colors.css"    "$theme_dir/wofi-colors.css"

    echo "$wallpaper" > "$theme_dir/wallpaper.txt"
    touch "$theme_dir/.complete"

    log "✓ Theme cached"
    return 0
}

if [[ $# -lt 2 ]]; then
    error "Usage: $0 <wallpaper> <theme_dir>"
    exit 1
fi

generate_theme "$1" "$2"
