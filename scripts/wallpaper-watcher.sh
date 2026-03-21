#!/bin/bash

# ============================================================================
# WALLPAPER DIRECTORY WATCHER
# ============================================================================
# Monitors wallpapers directory for new files and auto-applies themes
# ============================================================================

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
THEME_ENGINE="$HOME/.config/hypr/scripts/theme-engine.sh"
WATCH_LOG="$HOME/.cache/wallpaper-watcher.log"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$WATCH_LOG"
}

log_info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$WATCH_LOG"
}

# Check if inotify-tools is installed
if ! command -v inotifywait &> /dev/null; then
    log "inotify-tools not found, using polling method..."
    
    # Fallback: polling method
    declare -A seen_files
    
    # Initialize with existing files
    for file in "$WALLPAPERS_DIR"/*; do
        if [[ -f "$file" && "$file" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            seen_files["$file"]=1
        fi
    done
    
    log "Watching $WALLPAPERS_DIR for new wallpapers (polling mode)..."
    
    while true; do
        for file in "$WALLPAPERS_DIR"/*; do
            if [[ -f "$file" && "$file" =~ \.(jpg|jpeg|png|webp)$ ]]; then
                if [ -z "${seen_files[$file]}" ]; then
                    log "New wallpaper detected: $(basename "$file")"
                    seen_files["$file"]=1
                    sleep 2  # Wait for file to be fully written
                    "$THEME_ENGINE" apply "$file"
                fi
            fi
        done
        sleep 5
    done
else
    # Use inotifywait for efficient monitoring
    log "Watching $WALLPAPERS_DIR for new wallpapers (inotify mode)..."
    
    inotifywait -m -e close_write -e moved_to "$WALLPAPERS_DIR" |
    while read -r directory events filename; do
        if [[ "$filename" =~ \.(jpg|jpeg|png|webp)$ ]]; then
            log "New wallpaper detected: $filename"
            sleep 1  # Wait for file to be fully written
            "$THEME_ENGINE" apply "$WALLPAPERS_DIR/$filename"
        fi
    done
fi
