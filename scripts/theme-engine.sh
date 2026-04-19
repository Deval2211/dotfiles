#!/bin/bash
# ============================================================================
# HYPRLAND AUTOMATED THEMING ENGINE
# ============================================================================

set -euo pipefail

CONFIG_DIR="$HOME/.config"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
THEMES_DIR="$HOME/.cache/hypr-themes"
LOG_FILE="$HOME/.cache/theme-engine.log"
CURRENT_THEME="$HOME/.cache/.current_theme"

mkdir -p "$WALLPAPERS_DIR" "$THEMES_DIR"

# ============================================================================
# LOGGING
# ============================================================================

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[$(date +'%H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }
warn()  { echo "[$(date +'%H:%M:%S')] WARN: $*"  | tee -a "$LOG_FILE"; }

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

check_deps() {
    local deps=(matugen convert md5sum hyprctl)
    local missing=()
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# ============================================================================
# HASH & CACHE
# ============================================================================

get_hash() {
    md5sum "$1" | cut -d' ' -f1
}

theme_cached() {
    [[ -d "$THEMES_DIR/$1" ]] && [[ -f "$THEMES_DIR/$1/.complete" ]]
}

load_cache() {
    local hash="$1"
    log "Loading cached theme: $hash"

    [[ -f "$THEMES_DIR/$hash/hyprland-colors.conf" ]] && cp "$THEMES_DIR/$hash/hyprland-colors.conf" "$CONFIG_DIR/hypr/colors.conf"
    [[ -f "$THEMES_DIR/$hash/kitty-colors.conf"    ]] && cp "$THEMES_DIR/$hash/kitty-colors.conf"    "$CONFIG_DIR/kitty/colors.conf"
    [[ -f "$THEMES_DIR/$hash/waybar-colors.css"    ]] && cp "$THEMES_DIR/$hash/waybar-colors.css"    "$CONFIG_DIR/waybar/colors.css"
    [[ -f "$THEMES_DIR/$hash/wofi-colors.css"      ]] && cp "$THEMES_DIR/$hash/wofi-colors.css"      "$CONFIG_DIR/wofi/colors.css"

    log "✓ Cache loaded"
}

# ============================================================================
# WALLPAPER
# ============================================================================

set_wallpaper() {
    local wallpaper="$1"

    if ! pgrep -x swww-daemon >/dev/null; then
        warn "Starting swww-daemon..."
        swww-daemon &
        sleep 2
    fi

    # Auto-detect correct WAYLAND_DISPLAY for swww-daemon
    local swww_pid
    swww_pid=$(pgrep -x swww-daemon | head -1)
    if [[ -n "$swww_pid" ]]; then
        local swww_display
        swww_display=$(cat /proc/"$swww_pid"/environ 2>/dev/null | tr '\0' '\n' | grep ^WAYLAND_DISPLAY= | cut -d= -f2)
        [[ -n "$swww_display" ]] && export WAYLAND_DISPLAY="$swww_display"
    fi

    log "Setting wallpaper: $(basename "$wallpaper")"
    swww img "$wallpaper" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 60 2>>"$LOG_FILE" && log "✓ Wallpaper set" || warn "swww failed (non-fatal)"
}

# ============================================================================
# MAIN APPLY
# ============================================================================

apply_theme() {
    local wallpaper="$1"

    [[ ! -f "$wallpaper" ]] && error "Wallpaper not found: $wallpaper" && return 1

    log "=========================================="
    log "  APPLYING THEME"
    log "=========================================="
    log "Wallpaper: $(basename "$wallpaper")"

    local hash
    hash=$(get_hash "$wallpaper")
    log "Hash: $hash"

    if theme_cached "$hash"; then
        log "✓ Theme cached — loading instantly"
        load_cache "$hash"
    else
        log "Generating new theme..."
        local theme_dir="$THEMES_DIR/$hash"
        mkdir -p "$theme_dir"

        if ! "$CONFIG_DIR/hypr/scripts/generate_theme.sh" "$wallpaper" "$theme_dir"; then
            error "Theme generation failed"
            rm -rf "$theme_dir"
            return 1
        fi
    fi

    set_wallpaper "$wallpaper"

    "$CONFIG_DIR/hypr/scripts/reload.sh"

    echo "$wallpaper" > "$CURRENT_THEME"
    echo "$hash"      >> "$CURRENT_THEME"

    log "=========================================="
    log "  ✓ THEME APPLIED SUCCESSFULLY"
    log "=========================================="
}

# ============================================================================
# HELPERS
# ============================================================================

list_wallpapers() {
    local i=1
    for wp in "$WALLPAPERS_DIR"/*; do
        [[ -f "$wp" && "$wp" =~ \.(jpg|jpeg|png|webp)$ ]] && echo "  [$i] $(basename "$wp")" && ((i++))
    done
}

get_random() {
    local wallpapers=()
    for wp in "$WALLPAPERS_DIR"/*; do
        [[ -f "$wp" && "$wp" =~ \.(jpg|jpeg|png|webp)$ ]] && wallpapers+=("$wp")
    done
    [[ ${#wallpapers[@]} -eq 0 ]] && error "No wallpapers found" && return 1
    echo "${wallpapers[$((RANDOM % ${#wallpapers[@]}))]}"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    check_deps

    case "${1:-}" in
        apply)
            [[ -z "${2:-}" ]] && error "Usage: $0 apply <wallpaper>" && exit 1
            apply_theme "$2"
            ;;
        random)
            apply_theme "$(get_random)"
            ;;
        list)
            list_wallpapers
            ;;
        current)
            [[ -f "$CURRENT_THEME" ]] && cat "$CURRENT_THEME" || warn "No theme applied"
            ;;
        clean)
            warn "Cleaning cache..."
            rm -rf "$THEMES_DIR"/*
            log "✓ Cache cleaned"
            ;;
        *)
            echo "Usage: $0 {apply <path>|random|list|current|clean}"
            exit 1
            ;;
    esac
}

main "$@"
