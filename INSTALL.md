# AGS Dashboard Installation Guide

This repository contains a complete AGS (Aylur's GTK Shell) dashboard configuration for Hyprland with dynamic Material 3 theming via Matugen.

## Quick Start

### Automatic Installation (Recommended)

```bash
git clone https://github.com/Deval2211/dotfiles.git
cd dotfiles
./install.sh
```

The installation script will:
1. Install all system dependencies
2. Install AGS binary globally
3. Copy configuration files to `~/.config/`
4. Install npm dependencies
5. Build and install Astal 3.0 libraries from source
6. Verify the installation

### Manual Installation

If you prefer to install manually, follow these steps:

#### 1. Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y meson ninja-build valac gcc g++ pkg-config git \
  libgtk-4-dev libadwaita-1-dev libgtk-3-dev libgdk-pixbuf2.0-dev \
  libglib2.0-dev libgobject-introspection-1.0-dev gir1.2-gtk-4.0 \
  gir1.2-adwaita-1 gir1.2-appstream-1.0 libappstream-dev \
  libjson-glib-dev g-ir-compiler gtk-doc-tools valadoc
```

**Arch:**
```bash
sudo pacman -Sy --noconfirm meson ninja base-devel gtk4 libadwaita gtk3 \
  gdk-pixbuf glib2 gobject-introspection json-glib gtk-doc valadoc
```

#### 2. Install AGS

```bash
npm install -g ags
# or
sudo npm install -g ags
```

#### 3. Copy Configuration Files

```bash
cp -r ags ~/.config/
cp -r hypr ~/.config/
cp -r matugen ~/.config/
```

#### 4. Install NPM Dependencies

```bash
cd ~/.config/ags
npm install
```

#### 5. Build Astal 3.0

```bash
git clone https://github.com/Aylur/astal /tmp/astal
cd /tmp/astal/lib/astal/io
rm -rf build && meson setup build
cd build && ninja && sudo ninja install

cd /tmp/astal/lib/astal/gtk3
rm -rf build && meson setup build
cd build && ninja && sudo ninja install

sudo ldconfig
```

## Configuration Structure

```
dotfiles/
├── ags/                          # AGS Application
│   ├── app.ts                    # Entry point
│   ├── package.json              # Dependencies (ags, gnim)
│   ├── tsconfig.json             # TypeScript configuration
│   ├── style.css                 # Dashboard styling (imports colors.css)
│   ├── widget/
│   │   ├── Dashboard.tsx         # Main dashboard component
│   │   └── CircularRing.ts       # Reusable circular stat ring
│   └── modules/
│       ├── cpu.ts                # CPU usage monitoring
│       ├── memory.ts             # Memory usage monitoring
│       └── network.ts            # Network speed monitoring
├── hypr/
│   └── hyprland.conf             # Hyprland configuration with AGS startup
├── matugen/
│   ├── config.toml               # Matugen color generation config
│   └── templates/                # Template files for dynamic theming
│       ├── ags-colors.css        # Generated Material 3 palette
│       ├── colors.css            # Color definitions
│       ├── gtk-colors.css        # GTK theme colors
│       ├── hyprland-colors.conf  # Hyprland theme colors
│       ├── rofi-colors.rasi      # Rofi theme colors
│       └── wezterm-colors.lua    # WezTerm theme colors
├── scripts/                      # Utility scripts
│   ├── generate_theme.sh         # Generate colors from image
│   ├── theme-engine.sh           # Theme engine
│   ├── wallpaper-watcher.sh      # Watch for wallpaper changes
│   └── reload.sh                 # Reload AGS and regenerate theme
└── install.sh                    # Automated installation script
```

## Features

### AGS Dashboard
- **Real-time System Monitoring**: CPU, Memory, and Network usage displayed as circular progress rings
- **Quick Access Panel**: 5 customizable action buttons (Terminal, Browser, Launcher, Lock, Power)
- **Time & Date Display**: Current time and date in the dashboard header
- **Glassmorphic Design**: Semi-transparent background with border effects
- **Auto-hide on Inactivity**: Dashboard disappears when not interacting

### Dynamic Theming
- **Material Design 3**: Automatically generated color palettes from wallpaper
- **Cross-Application**: Themes applied to GTK, Rofi, WezTerm, and Hyprland
- **Real-time Updates**: Colors regenerated when wallpaper changes
- **Consistent Styling**: All components use the same color scheme

### Hyprland Integration
- **Automatic Startup**: AGS dashboard launches with Hyprland
- **Keybinding**: Super+D to toggle dashboard visibility
- **Position**: Top-right overlay, non-intrusive
- **Window Manager**: Proper window decoration and layering

## Usage

### Toggle Dashboard
```bash
# Press Super+D in Hyprland
# or manually:
ags toggle-window -w dashboard
```

### Reload Configuration
```bash
~/.config/hypr/scripts/reload.sh
```

### Generate Theme from Image
```bash
~/.config/hypr/scripts/generate_theme.sh /path/to/image.jpg
# or with random wallpaper:
~/.config/hypr/scripts/theme-engine.sh random
```

### View Logs
```bash
# AGS logs
tail -f ~/.cache/ags.log

# Hyprland logs
tail -f ~/.cache/hyprland.log
```

## Troubleshooting

### AGS doesn't start
1. Check Astal typelib is installed:
   ```bash
   pkg-config --list-all | grep -i astal
   # or
   ls -la /usr/local/lib/x86_64-linux-gnu/girepository-1.0/Astal*.typelib
   ```

2. Check AGS logs:
   ```bash
   tail -f ~/.cache/ags.log
   ```

3. Try running AGS manually:
   ```bash
   export LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
   ags run --directory ~/.config/ags
   ```

### Dashboard not visible
1. Check Hyprland configuration has correct path in `exec-once`:
   ```bash
   grep "ags run" ~/.config/hypr/hyprland.conf
   ```

2. Reload Hyprland: Super+Shift+E

3. Check if AGS process is running:
   ```bash
   ps aux | grep ags
   ```

### Build fails on Astal compilation
1. Ensure all dependencies are installed:
   ```bash
   sudo apt-get install valadoc gtk-doc-tools g-ir-compiler
   ```

2. Try cleaning and rebuilding:
   ```bash
   cd /tmp/astal/lib/astal/gtk3/build
   rm -rf build && meson setup build
   ninja
   ```

3. Check Meson output for missing packages:
   ```bash
   meson setup build --wipe
   ```

## Dependencies

### System
- Meson 1.3+
- Ninja 1.11+
- Vala 0.56+
- GLib 2.74+
- GTK 4.0+
- Libadwaita 1.0+

### Node/npm
- ags (npm)
- gnim (npm)

### Build (Astal)
- G-IR Compiler
- valadoc
- gtk-doc-tools

## Optional Dependencies

- **Matugen**: For dynamic theme generation from wallpaper colors
  - Install: `cargo install matugen`
  - GitHub: https://github.com/InioX/Matugen

- **swww**: For animated wallpaper support
  - Install: `cargo install swww`
  - GitHub: https://github.com/LGFae/swww

- **Rofi**: For application launcher
  - Install: `sudo apt-get install rofi`

- **Hyprland**: Wayland compositor
  - Install: https://hyprland.org

## Customization

### Change Dashboard Position
Edit `~/.config/ags/widget/Dashboard.tsx`:
```typescript
// Change anchor from TOP|RIGHT to desired position
anchor: [Astal.WindowAnchor.TOP, Astal.WindowAnchor.RIGHT],
```

### Add More Widgets
Add new `.ts` modules in `~/.config/ags/modules/` and import them in `Dashboard.tsx`.

### Customize Colors
Edit `~/.config/matugen/config.toml` to change color generation settings, or edit `~/.config/ags/colors.css` directly.

### Add Quick Action Buttons
Edit the `QuickActions` component in `~/.config/ags/widget/Dashboard.tsx` to add more buttons or change actions.

## Performance

- Dashboard typically uses <100MB RAM
- CPU monitoring updates every 2 seconds
- Memory updates every 3 seconds
- Network updates every 2 seconds
- Minimal impact on system performance

## License

Customize as needed for your own use.

## Support

For issues with:
- **AGS**: https://github.com/Aylur/ags
- **Astal**: https://github.com/Aylur/astal
- **Hyprland**: https://github.com/hyprwm/Hyprland
- **Matugen**: https://github.com/InioX/Matugen

---

Enjoy your AGS dashboard! 🎨
