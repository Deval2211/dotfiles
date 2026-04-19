#!/bin/bash

# AGS Dashboard Configuration Installer
# This script installs all dependencies and configures the AGS dashboard system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "This script only works on Linux"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
TEMP_BUILD_DIR="/tmp/astal"

log_info "Starting AGS Dashboard installation..."
log_info "Script directory: $SCRIPT_DIR"
log_info "Config directory: $CONFIG_DIR"

###############################################
# 1. SYSTEM DEPENDENCIES
###############################################

log_info "================================"
log_info "Installing system dependencies..."
log_info "================================"

# Update package manager
if command -v apt-get &> /dev/null; then
    log_info "Detected: Ubuntu/Debian-based system"
    sudo apt-get update -qq
    
    # Core dependencies
    PACKAGES=(
        # Build tools
        "meson"
        "ninja-build"
        "valac"
        "gcc"
        "g++"
        "pkg-config"
        "git"
        
        # GTK and dependencies
        "libgtk-4-dev"
        "libadwaita-1-dev"
        "libgtk-3-dev"
        "libgdk-pixbuf2.0-dev"
        "libgdk-pixbuf-xlib-2.0-dev"
        
        # GLib/GObject
        "libglib2.0-dev"
        "libgobject-introspection-1.0-dev"
        "gir1.2-gtk-4.0"
        "gir1.2-adwaita-1"
        "gir1.2-appstream-1.0"
        "libappstream-dev"
        
        # JSON and utilities
        "libjson-glib-dev"
        "g-ir-compiler"
        
        # Documentation tools
        "gtk-doc-tools"
        "valadoc"
        
        # Runtime dependencies
        "libnotify-bin"
        "imagemagick"
    )
    
    log_info "Installing packages: ${#PACKAGES[@]} packages"
    for pkg in "${PACKAGES[@]}"; do
        if ! sudo apt-get install -y "$pkg" > /dev/null 2>&1; then
            log_warning "Failed to install $pkg (might already be installed)"
        fi
    done
    
    log_success "System dependencies installed"
    
elif command -v pacman &> /dev/null; then
    log_info "Detected: Arch-based system"
    sudo pacman -Sy --noconfirm \
        meson ninja base-devel gtk4 libadwaita gtk3 gdk-pixbuf \
        glib2 gobject-introspection gtksourceview5 json-glib \
        gtk-doc valadoc imagemagick libnotify
    log_success "System dependencies installed"
    
else
    log_error "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

###############################################
# 2. INSTALL AGS BINARY
###############################################

log_info "================================"
log_info "Installing AGS binary..."
log_info "================================"

if ! command -v ags &> /dev/null; then
    log_info "AGS not found, installing via npm..."
    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Please install Node.js first."
        exit 1
    fi
    sudo npm install -g ags
    log_success "AGS installed globally"
else
    AGS_VERSION=$(ags --version 2>/dev/null || echo "unknown")
    log_success "AGS already installed (version: $AGS_VERSION)"
fi

###############################################
# 3. COPY CONFIGURATION FILES
###############################################

log_info "================================"
log_info "Copying configuration files..."
log_info "================================"

# Create config directories
mkdir -p "$CONFIG_DIR/ags"
mkdir -p "$CONFIG_DIR/ags/widget"
mkdir -p "$CONFIG_DIR/ags/modules"
mkdir -p "$CONFIG_DIR/hypr"
mkdir -p "$CONFIG_DIR/matugen"

# Copy AGS configuration
log_info "Copying AGS files..."
cp -v "$SCRIPT_DIR/ags/app.ts" "$CONFIG_DIR/ags/"
cp -v "$SCRIPT_DIR/ags/package.json" "$CONFIG_DIR/ags/"
cp -v "$SCRIPT_DIR/ags/tsconfig.json" "$CONFIG_DIR/ags/"
cp -v "$SCRIPT_DIR/ags/style.css" "$CONFIG_DIR/ags/"
cp -rv "$SCRIPT_DIR/ags/widget/"* "$CONFIG_DIR/ags/widget/" 2>/dev/null || true
cp -rv "$SCRIPT_DIR/ags/modules/"* "$CONFIG_DIR/ags/modules/" 2>/dev/null || true
log_success "AGS files copied"

# Copy Hyprland configuration
log_info "Copying Hyprland configuration..."
cp -v "$SCRIPT_DIR/hypr/hyprland.conf" "$CONFIG_DIR/hypr/"
cp -v "$SCRIPT_DIR/hypr/colors.conf" "$CONFIG_DIR/hypr/" 2>/dev/null || true
log_success "Hyprland configuration copied"

# Copy Matugen configuration
log_info "Copying Matugen configuration..."
cp -v "$SCRIPT_DIR/matugen/config.toml" "$CONFIG_DIR/matugen/"
mkdir -p "$CONFIG_DIR/matugen/templates"
cp -v "$SCRIPT_DIR/matugen/templates/"* "$CONFIG_DIR/matugen/templates/" 2>/dev/null || true
log_success "Matugen configuration copied"

###############################################
# 4. INSTALL NPM DEPENDENCIES FOR AGS
###############################################

log_info "================================"
log_info "Installing AGS npm dependencies..."
log_info "================================"

cd "$CONFIG_DIR/ags"
if [ -f "package.json" ]; then
    npm install
    log_success "AGS dependencies installed"
else
    log_warning "package.json not found in $CONFIG_DIR/ags"
fi

###############################################
# 5. BUILD ASTAL LIBRARIES
###############################################

log_info "================================"
log_info "Building Astal 3.0 libraries..."
log_info "================================"

# Clone/update Astal repository
if [ ! -d "$TEMP_BUILD_DIR" ]; then
    log_info "Cloning Astal repository..."
    git clone https://github.com/Aylur/astal "$TEMP_BUILD_DIR"
else
    log_info "Astal repository already exists, updating..."
    cd "$TEMP_BUILD_DIR"
    git pull
fi

# Create version file if it doesn't exist
echo "0.1.0" > "$TEMP_BUILD_DIR/version"

# Build astal-io (base library)
log_info "Building astal-io (0.1.0)..."
cd "$TEMP_BUILD_DIR/lib/astal/io"
rm -rf build
meson setup build
cd build
ninja
sudo ninja install
log_success "astal-io installed"

# Build astal GTK3 (required by AGS)
log_info "Building astal GTK3 (3.0.0)..."
cd "$TEMP_BUILD_DIR/lib/astal/gtk3"
rm -rf build
meson setup build
cd build
ninja
sudo ninja install
log_success "astal GTK3 installed"

# Update library cache
log_info "Updating library cache..."
sudo ldconfig

###############################################
# 6. VERIFY INSTALLATION
###############################################

log_info "================================"
log_info "Verifying installation..."
log_info "================================"

# Check AGS
if command -v ags &> /dev/null; then
    log_success "✓ AGS is installed"
else
    log_error "✗ AGS is not found"
fi

# Check Astal typelib
if pkg-config --exists Astal-3.0 2>/dev/null; then
    log_success "✓ Astal 3.0 is available"
else
    log_warning "Astal 3.0 typelib not found in pkg-config"
    # Try to find it directly
    if find /usr/local/lib -name "Astal*.typelib" 2>/dev/null | grep -q Astal; then
        log_success "✓ Astal typelib found in system libraries"
    fi
fi

# Check config files
log_info "Checking configuration files..."
[ -f "$CONFIG_DIR/ags/app.ts" ] && log_success "✓ AGS app.ts" || log_error "✗ AGS app.ts missing"
[ -f "$CONFIG_DIR/ags/style.css" ] && log_success "✓ AGS style.css" || log_error "✗ AGS style.css missing"
[ -f "$CONFIG_DIR/hypr/hyprland.conf" ] && log_success "✓ Hyprland config" || log_error "✗ Hyprland config missing"
[ -f "$CONFIG_DIR/matugen/config.toml" ] && log_success "✓ Matugen config" || log_error "✗ Matugen config missing"

###############################################
# 7. SETUP COMPLETE
###############################################

log_info "================================"
log_success "Installation complete!"
log_info "================================"

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Start/reload Hyprland session (press Super+Shift+E or reboot)"
echo "2. The AGS dashboard will start automatically"
echo "3. Press Super+D to toggle the dashboard visibility"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "• If AGS doesn't start, check: tail -f ~/.cache/ags.log"
echo "• If Astal typelib is missing, run: export LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
echo "• For Hyprland env vars, check: ~/.config/hypr/hyprland.conf line with 'ags run'"
echo ""
echo -e "${YELLOW}Optional:${NC}"
echo "• Install Matugen for dynamic theming: https://github.com/InioX/Matugen"
echo "• Configure wallpaper-watcher.sh for automatic theme generation on wallpaper change"
echo ""
