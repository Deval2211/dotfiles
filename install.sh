#!/bin/bash

# ============================================================================
# HYPRLAND THEME ENGINE - INSTALLATION & SETUP
# ============================================================================

set -e

# Get the actual directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Parse command-line arguments
AUTO_INSTALL=false
SKIP_DEPS=false

for arg in "$@"; do
    case $arg in
        --auto)
            AUTO_INSTALL=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto        Automatically install dependencies without prompting"
            echo "  --skip-deps   Skip dependency installation"
            echo "  --help        Show this help message"
            exit 0
            ;;
    esac
done

echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     HYPRLAND AUTOMATED THEMING ENGINE                     ║
║     Installation & Setup                                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running on supported distro
echo -e "${YELLOW}Checking system...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected: $NAME"
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Function to install packages based on distro
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    
    case "$ID" in
        ubuntu|debian|linuxmint)
            sudo apt update
            sudo apt install -y \
                hyprland \
                waybar \
                kitty \
                wofi \
                swww \
                grim \
                slurp \
                wl-clipboard \
                imagemagick \
                libnotify-bin \
                inotify-tools \
                jq
            
            # Install matugen
            if ! command -v matugen &> /dev/null; then
                echo "Installing matugen..."
                cargo install matugen || {
                    echo -e "${RED}Failed to install matugen. Please install Rust first:${NC}"
                    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
                    exit 1
                }
            fi
            ;;
        
        kali)
            sudo apt update
            sudo apt install -y \
                hyprland \
                waybar \
                kitty \
                wofi \
                grim \
                slurp \
                wl-clipboard \
                imagemagick \
                libnotify-bin \
                inotify-tools \
                jq
            
            # Install swww manually for Kali
            if ! command -v swww &> /dev/null; then
                echo "Installing swww..."
                cargo install swww || {
                    echo -e "${YELLOW}swww installation failed, continuing...${NC}"
                }
            fi
            
            # Install matugen
            if ! command -v matugen &> /dev/null; then
                echo "Installing matugen..."
                cargo install matugen || {
                    echo -e "${RED}Failed to install matugen${NC}"
                    exit 1
                }
            fi
            ;;
        
        arch|manjaro)
            sudo pacman -Sy --noconfirm \
                hyprland \
                waybar \
                kitty \
                wofi \
                swww \
                grim \
                slurp \
                wl-clipboard \
                imagemagick \
                libnotify \
                inotify-tools \
                jq \
                matugen
            ;;
        
        *)
            echo -e "${RED}Unsupported distribution: $ID${NC}"
            echo "Please install dependencies manually"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Dependencies installed ✓${NC}"
}

# Make scripts executable
make_executable() {
    echo -e "${YELLOW}Making scripts executable...${NC}"
    chmod +x "$DOTFILES_DIR/scripts/"*.sh
    chmod +x "$DOTFILES_DIR/run.sh"
    echo -e "${GREEN}Scripts are now executable ✓${NC}"
}

# Deploy configuration files to ~/.config/
deploy_configs() {
    echo -e "${YELLOW}Deploying configuration files...${NC}"
    
    # Create config directories
    mkdir -p "$CONFIG_DIR/hypr/scripts"
    mkdir -p "$CONFIG_DIR/waybar/scripts"
    mkdir -p "$CONFIG_DIR/kitty"
    mkdir -p "$CONFIG_DIR/wofi"
    mkdir -p "$CONFIG_DIR/matugen/templates"
    mkdir -p "$WALLPAPERS_DIR"
    
    # Copy Hyprland configs
    cp "$DOTFILES_DIR/hypr/hyprland.conf" "$CONFIG_DIR/hypr/"
    cp "$DOTFILES_DIR/scripts/theme-engine.sh" "$CONFIG_DIR/hypr/scripts/"
    cp "$DOTFILES_DIR/scripts/wallpaper-watcher.sh" "$CONFIG_DIR/hypr/scripts/"
    cp "$DOTFILES_DIR/scripts/wallpaper-selector.sh" "$CONFIG_DIR/hypr/scripts/"
    cp "$DOTFILES_DIR/scripts/screenshot.sh" "$CONFIG_DIR/hypr/scripts/"
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh
    
    # Copy Waybar configs
    cp "$DOTFILES_DIR/waybar/config.jsonc" "$CONFIG_DIR/waybar/"
    cp "$DOTFILES_DIR/waybar/style.css" "$CONFIG_DIR/waybar/"
    cp "$DOTFILES_DIR/waybar/scripts/launch.sh" "$CONFIG_DIR/waybar/scripts/"
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh
    
    # Copy Kitty configs
    cp "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/"
    
    # Copy Wofi configs
    cp "$DOTFILES_DIR/wofi/config" "$CONFIG_DIR/wofi/"
    cp "$DOTFILES_DIR/wofi/style.css" "$CONFIG_DIR/wofi/"
    
    # Copy Matugen configs
    cp "$DOTFILES_DIR/matugen/config.toml" "$CONFIG_DIR/matugen/"
    cp -r "$DOTFILES_DIR/matugen/templates/"* "$CONFIG_DIR/matugen/templates/" 2>/dev/null || true
    
    # Copy wallpapers if they exist
    if [ -d "$DOTFILES_DIR/wallpapers" ] && [ -n "$(find "$DOTFILES_DIR/wallpapers" -type f 2>/dev/null)" ]; then
        cp "$DOTFILES_DIR/wallpapers/"* "$WALLPAPERS_DIR/" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}Configuration files deployed to ~/.config/ ✓${NC}"
}

# Create necessary directories
create_directories() {
    echo -e "${YELLOW}Creating directories...${NC}"
    mkdir -p "$DOTFILES_DIR/themes"
    mkdir -p "$DOTFILES_DIR/gtk"
    mkdir -p "$HOME/.cache/hypr-themes"
    mkdir -p "$HOME/.cache/wallpaper-selector"
    mkdir -p "$HOME/Pictures/Screenshots"
    echo -e "${GREEN}Directories created ✓${NC}"
}

# Test theme engine
test_theme_engine() {
    echo -e "${YELLOW}Testing theme engine...${NC}"
    
    if [ -f "$CONFIG_DIR/hypr/scripts/theme-engine.sh" ]; then
        "$CONFIG_DIR/hypr/scripts/theme-engine.sh" list > /dev/null 2>&1 || true
        echo -e "${GREEN}Theme engine is working ✓${NC}"
    else
        echo -e "${RED}Theme engine script not found at ~/.config/hypr/scripts/theme-engine.sh${NC}"
        exit 1
    fi
}

# Main installation
main() {
    # Handle dependency installation
    if [ "$SKIP_DEPS" = false ]; then
        if [ "$AUTO_INSTALL" = true ]; then
            echo -e "${YELLOW}Auto-installing dependencies (--auto flag detected)...${NC}"
            install_dependencies
        else
            echo ""
            read -p "Install dependencies? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_dependencies
            fi
        fi
    else
        echo -e "${YELLOW}Skipping dependency installation (--skip-deps flag)${NC}"
    fi
    
    create_directories
    make_executable
    deploy_configs
    test_theme_engine
    
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     INSTALLATION COMPLETE!                                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "Quick Start Guide:"
    echo ""
    echo "1. Apply a random theme:"
    echo "   ~/.config/hypr/scripts/theme-engine.sh random"
    echo ""
    echo "2. Select wallpaper interactively:"
    echo "   ~/.config/hypr/scripts/wallpaper-selector.sh"
    echo ""
    echo "3. Apply specific wallpaper:"
    echo "   ~/.config/hypr/scripts/theme-engine.sh apply /path/to/wallpaper.jpg"
    echo ""
    echo "4. Start Hyprland with custom config:"
    echo "   hyprland -c ~/.config/hypr/hyprland.conf"
    echo ""
    echo "5. Add to Hyprland autostart (hyprland.conf):"
    echo "   exec-once = ~/.config/hypr/scripts/wallpaper-watcher.sh"
    echo ""
    echo "Keybindings (configured in ~/.config/hypr/hyprland.conf):"
    echo "  SUPER + B         - Open wallpaper selector"
    echo "  SUPER + SHIFT + B - Apply random wallpaper"
    echo ""
    echo "For auto-detection of new wallpapers:"
    echo "   ~/.config/hypr/scripts/wallpaper-watcher.sh"
    echo ""
    echo -e "${YELLOW}Installation Options:${NC}"
    echo "  Re-run with --auto to auto-install dependencies without prompting"
    echo "  Re-run with --skip-deps to skip dependency installation"
    echo "  Run with --help to see all options"
    echo ""
}

main
