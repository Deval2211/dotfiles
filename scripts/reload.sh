#!/bin/bash
# Reload Script - Safely reload all themed components

set -euo pipefail

LOG_FILE="$HOME/.cache/theme-engine.log"

log()   { echo "[$(date +'%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
error() { echo "[$(date +'%H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2; }

reload_mako() {
    if pgrep -x mako >/dev/null; then
        log "Reloading Mako..."
        makoctl reload 2>>/dev/null && log "✓ Mako reloaded" || error "✗ Mako reload failed"
    fi
}

reload_hyprland() {
    if command -v hyprctl &>/dev/null; then
        log "Reloading Hyprland..."
        hyprctl reload 2>>"$LOG_FILE" && log "✓ Hyprland reloaded" || error "✗ Hyprland reload failed"
    fi
}

reload_waybar() {
    if pgrep -x waybar >/dev/null; then
        log "Reloading Waybar..."
        killall -SIGUSR2 waybar 2>/dev/null && log "✓ Waybar reloaded" || {
            killall waybar 2>/dev/null
            sleep 0.5
            waybar &
            log "✓ Waybar restarted"
        }
    fi
}

reload_kitty() {
    if pgrep -x kitty >/dev/null; then
        log "Reloading Kitty..."
        killall -SIGUSR1 kitty 2>/dev/null && log "✓ Kitty reloaded" || error "✗ Kitty reload failed"
    fi
}

reload_gtk() {
    if command -v gsettings &>/dev/null; then
        log "Reloading GTK..."
        gsettings set org.gnome.desktop.interface gtk-theme '' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        log "✓ GTK reloaded"
    fi
}

log "=========================================="
log "  RELOADING COMPONENTS"
log "=========================================="

reload_hyprland
reload_waybar
reload_kitty
reload_mako
reload_gtk

log "=========================================="
log "  ✓ RELOAD COMPLETE"
log "=========================================="
