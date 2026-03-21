#!/bin/bash

# ============================================================================
# HYPRLAND AUTOMATED THEMING ENGINE
# ============================================================================
# A production-level theming system with caching, auto-detection, and
# full system integration for Hyprland desktop environment.
# ============================================================================

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

CONFIG_DIR="$HOME/.config"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
THEMES_DIR="$HOME/.cache/hypr-themes"
LOG_FILE="$HOME/.cache/theme-engine.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
    log_info "Checking dependencies..."
    
    local deps=("matugen" "swww" "md5sum" "hyprctl" "killall")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Please install: ${missing[*]}"
        exit 1
    fi
    
    log "All dependencies satisfied ✓"
}

# ============================================================================
# WALLPAPER HASH GENERATION
# ============================================================================

get_wallpaper_hash() {
    local wallpaper="$1"
    md5sum "$wallpaper" | awk '{print $1}'
}

# ============================================================================
# THEME CACHE MANAGEMENT
# ============================================================================

theme_exists() {
    local hash="$1"
    [ -d "$THEMES_DIR/$hash" ] && [ -f "$THEMES_DIR/$hash/.complete" ]
}

create_theme_cache() {
    local hash="$1"
    local wallpaper="$2"
    
    log_info "Creating theme cache for: $(basename "$wallpaper")"
    
    # Create theme directory
    mkdir -p "$THEMES_DIR/$hash"
    
    # Store wallpaper path
    echo "$wallpaper" > "$THEMES_DIR/$hash/wallpaper.txt"
    
    # Generate theme using matugen
    log_info "Running matugen to generate color scheme..."
    
    # Use absolute path for wallpaper
    local abs_wallpaper=$(realpath "$wallpaper")
    
    # Extract dominant color from image using imagemagick
    log_info "Extracting dominant color from wallpaper..."
    local source_color=$(convert "$abs_wallpaper" -resize 1x1\! -format "#%[hex:u]" info:- 2>&1)
    
    if [ -z "$source_color" ] || [[ ! "$source_color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        log_error "Failed to extract color from wallpaper"
        rm -rf "$THEMES_DIR/$hash"
        return 1
    fi
    
    log_info "Using source color: $source_color"
    
    # Generate theme using the extracted color
    if ! matugen color hex "$source_color" > "$THEMES_DIR/$hash/colors.json" 2>&1; then
        log_error "Matugen failed to generate theme"
        rm -rf "$THEMES_DIR/$hash"
        return 1
    fi
    
    # Copy generated configs to theme cache
    log_info "Caching generated configurations..."
    
    # Hyprland colors
    if [ -f "$CONFIG_DIR/hypr/colors.conf" ]; then
        cp "$CONFIG_DIR/hypr/colors.conf" "$THEMES_DIR/$hash/hyprland-colors.conf"
    fi
    
    # Kitty colors
    if [ -f "$CONFIG_DIR/kitty/colors.conf" ]; then
        cp "$CONFIG_DIR/kitty/colors.conf" "$THEMES_DIR/$hash/kitty-colors.conf"
    fi
    
    # Waybar colors
    if [ -f "$CONFIG_DIR/waybar/colors.css" ]; then
        cp "$CONFIG_DIR/waybar/colors.css" "$THEMES_DIR/$hash/waybar-colors.css"
    fi
    
    # Wofi colors (if exists)
    if [ -f "$CONFIG_DIR/wofi/colors.css" ]; then
        cp "$CONFIG_DIR/wofi/colors.css" "$THEMES_DIR/$hash/wofi-colors.css"
    fi
    
    # Mark cache as complete
    touch "$THEMES_DIR/$hash/.complete"
    
    log "Theme cache created successfully ✓"
    return 0
}

load_theme_from_cache() {
    local hash="$1"
    
    log_info "Loading theme from cache..."
    
    # Restore configs from cache
    [ -f "$THEMES_DIR/$hash/hyprland-colors.conf" ] && cp "$THEMES_DIR/$hash/hyprland-colors.conf" "$CONFIG_DIR/hypr/colors.conf"
    [ -f "$THEMES_DIR/$hash/kitty-colors.conf" ] && cp "$THEMES_DIR/$hash/kitty-colors.conf" "$CONFIG_DIR/kitty/colors.conf"
    [ -f "$THEMES_DIR/$hash/waybar-colors.css" ] && cp "$THEMES_DIR/$hash/waybar-colors.css" "$CONFIG_DIR/waybar/colors.css"
    [ -f "$THEMES_DIR/$hash/wofi-colors.css" ] && cp "$THEMES_DIR/$hash/wofi-colors.css" "$CONFIG_DIR/wofi/colors.css"
    
    log "Theme loaded from cache ✓"
}

# ============================================================================
# WALLPAPER APPLICATION
# ============================================================================

set_wallpaper() {
    local wallpaper="$1"
    
    log_info "Setting wallpaper: $(basename "$wallpaper")"
    
    # Check if swww daemon is running
    if ! pgrep -x swww-daemon > /dev/null; then
        log_warn "swww-daemon not running, starting it..."
        swww-daemon &
        sleep 2
    fi
    
    # Find the correct WAYLAND_DISPLAY for swww
    local swww_pid=$(pgrep -x swww-daemon | head -1)
    if [ -n "$swww_pid" ]; then
        local swww_wayland=$(cat /proc/$swww_pid/environ 2>/dev/null | tr '\0' '\n' | grep ^WAYLAND_DISPLAY= | cut -d= -f2)
        if [ -n "$swww_wayland" ] && [ "$swww_wayland" != "$WAYLAND_DISPLAY" ]; then
            log_info "Using swww-daemon on $swww_wayland"
            export WAYLAND_DISPLAY="$swww_wayland"
        fi
    fi
    
    # Set wallpaper with transition
    if swww img "$wallpaper" \
        --transition-type center \
        --transition-duration 1 \
        --transition-fps 60 2>&1 | tee -a "$LOG_FILE"; then
        log "Wallpaper set successfully ✓"
        return 0
    else
        log_error "Failed to set wallpaper"
        return 1
    fi
}

# ============================================================================
# SYSTEM RELOAD
# ============================================================================

reload_applications() {
    log_info "Reloading applications..."
    
    # Reload Hyprland
    if command -v hyprctl &> /dev/null; then
        log_info "Reloading Hyprland configuration..."
        hyprctl reload 2>&1 | tee -a "$LOG_FILE" || log_warn "Hyprland reload failed"
    fi
    
    # Reload Waybar
    if pgrep -x waybar > /dev/null; then
        log_info "Reloading Waybar..."
        killall -SIGUSR2 waybar 2>/dev/null || {
            killall waybar 2>/dev/null
            sleep 0.5
            waybar &
        }
    fi
    
    # Reload Kitty (send signal to all instances)
    if pgrep -x kitty > /dev/null; then
        log_info "Reloading Kitty configurations..."
        killall -SIGUSR1 kitty 2>/dev/null || log_warn "Kitty reload signal failed"
    fi
    
    log "Applications reloaded ✓"
}

# ============================================================================
# VALIDATION
# ============================================================================

validate_configs() {
    log_info "Validating generated configurations..."
    
    local errors=0
    
    # Check Hyprland colors
    if [ -f "$CONFIG_DIR/hypr/colors.conf" ]; then
        if grep -q "rgba(" "$CONFIG_DIR/hypr/colors.conf"; then
            log "Hyprland colors valid ✓"
        else
            log_error "Hyprland colors.conf appears invalid"
            ((errors++))
        fi
    else
        log_error "Hyprland colors.conf not found"
        ((errors++))
    fi
    
    # Check Waybar colors
    if [ -f "$CONFIG_DIR/waybar/colors.css" ]; then
        if grep -q "@define-color" "$CONFIG_DIR/waybar/colors.css"; then
            log "Waybar colors valid ✓"
        else
            log_error "Waybar colors.css appears invalid"
            ((errors++))
        fi
    else
        log_error "Waybar colors.css not found"
        ((errors++))
    fi
    
    # Check Kitty colors
    if [ -f "$CONFIG_DIR/kitty/colors.conf" ]; then
        if grep -q "foreground" "$CONFIG_DIR/kitty/colors.conf"; then
            log "Kitty colors valid ✓"
        else
            log_error "Kitty colors.conf appears invalid"
            ((errors++))
        fi
    else
        log_error "Kitty colors.conf not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log "All configurations validated successfully ✓"
        return 0
    else
        log_error "Configuration validation failed with $errors errors"
        return 1
    fi
}

# ============================================================================
# MAIN THEME APPLICATION
# ============================================================================

apply_theme() {
    local wallpaper="$1"
    
    if [ ! -f "$wallpaper" ]; then
        log_error "Wallpaper file not found: $wallpaper"
        return 1
    fi
    
    log ""
    log "=========================================="
    log "  APPLYING THEME"
    log "=========================================="
    log "Wallpaper: $(basename "$wallpaper")"
    
    # Get wallpaper hash
    local hash=$(get_wallpaper_hash "$wallpaper")
    log_info "Wallpaper hash: $hash"
    
    # Check if theme exists in cache
    if theme_exists "$hash"; then
        log "Theme found in cache, loading..."
        load_theme_from_cache "$hash"
    else
        log "Theme not cached, generating new theme..."
        if ! create_theme_cache "$hash" "$wallpaper"; then
            log_error "Failed to create theme"
            return 1
        fi
    fi
    
    # Validate configurations
    if ! validate_configs; then
        log_error "Configuration validation failed, aborting"
        return 1
    fi
    
    # Set wallpaper
    if ! set_wallpaper "$wallpaper"; then
        log_error "Failed to set wallpaper"
        return 1
    fi
    
    # Reload applications
    reload_applications
    
    # Save current theme
    echo "$wallpaper" > "$HOME/.cache/.current_theme"
    echo "$hash" >> "$HOME/.cache/.current_theme"
    
    log ""
    log "=========================================="
    log "  THEME APPLIED SUCCESSFULLY ✓"
    log "=========================================="
    log ""
    
    return 0
}

# ============================================================================
# WALLPAPER SELECTION
# ============================================================================

list_wallpapers() {
    log "Available wallpapers:"
    local i=1
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$wallpaper" && "$wallpaper" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            echo "  [$i] $(basename "$wallpaper")"
            ((i++))
        fi
    done
}

select_wallpaper_interactive() {
    list_wallpapers
    echo ""
    read -p "Select wallpaper number: " selection
    
    local i=1
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$wallpaper" && "$wallpaper" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            if [ "$i" -eq "$selection" ]; then
                echo "$wallpaper"
                return 0
            fi
            ((i++))
        fi
    done
    
    log_error "Invalid selection"
    return 1
}

# ============================================================================
# RANDOM WALLPAPER
# ============================================================================

get_random_wallpaper() {
    local wallpapers=()
    for wallpaper in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$wallpaper" && "$wallpaper" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            wallpapers+=("$wallpaper")
        fi
    done
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        log_error "No wallpapers found in $WALLPAPERS_DIR"
        return 1
    fi
    
    local random_index=$((RANDOM % ${#wallpapers[@]}))
    echo "${wallpapers[$random_index]}"
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
    # Create necessary directories
    mkdir -p "$THEMES_DIR"
    mkdir -p "$WALLPAPERS_DIR"
    
    # Check dependencies
    check_dependencies
    
    case "${1:-}" in
        apply)
            if [ -z "${2:-}" ]; then
                log_error "Usage: $0 apply <wallpaper_path>"
                exit 1
            fi
            apply_theme "$2"
            ;;
        
        select)
            wallpaper=$(select_wallpaper_interactive)
            if [ $? -eq 0 ]; then
                apply_theme "$wallpaper"
            fi
            ;;
        
        random)
            wallpaper=$(get_random_wallpaper)
            if [ $? -eq 0 ]; then
                apply_theme "$wallpaper"
            fi
            ;;
        
        list)
            list_wallpapers
            ;;
        
        current)
            if [ -f "$HOME/.cache/.current_theme" ]; then
                log "Current theme:"
                cat "$HOME/.cache/.current_theme"
            else
                log_warn "No theme currently applied"
            fi
            ;;
        
        clean)
            log_warn "Cleaning theme cache..."
            rm -rf "$THEMES_DIR"/*
            log "Cache cleaned ✓"
            ;;
        
        watch)
            log "Starting wallpaper directory watcher..."
            "$CONFIG_DIR/hypr/scripts/wallpaper-watcher.sh"
            ;;
        
        *)
            echo "Hyprland Automated Theming Engine"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  apply <path>    Apply theme from specific wallpaper"
            echo "  select          Interactive wallpaper selection"
            echo "  random          Apply random wallpaper theme"
            echo "  list            List available wallpapers"
            echo "  current         Show current theme info"
            echo "  clean           Clear theme cache"
            echo "  watch           Watch wallpapers directory for changes"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
