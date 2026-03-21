# Hyprland Automated Theming Engine 🎨

> A production-level, fully automated theming system for Hyprland with intelligent caching, dynamic color generation, and seamless application integration.

![Status](https://img.shields.io/badge/status-production-green)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Mint%20%7C%20Kali-blue)

## ✨ Features

### 🎯 Core Capabilities
- **Intelligent Theme Caching** - MD5-based caching system prevents redundant theme generation
- **Dynamic Color Extraction** - Uses Matugen to extract Material You colors from wallpapers
- **Seamless Integration** - Automatically themes Hyprland, Waybar, Kitty, Wofi, and GTK apps
- **Auto-Detection** - Watches wallpaper directory for new files and auto-applies themes
- **Smooth Transitions** - Beautiful wallpaper transitions with swww
- **Validation System** - Automatically validates generated configs before applying
- **Error Recovery** - Robust error handling with detailed logging

### 🎨 Themed Applications
- **Hyprland** - Window borders, shadows, and UI elements
- **Waybar** - Status bar with dynamic colors
- **Kitty** - Terminal with full color scheme
- **Wofi** - Application launcher styling
- **Nemo** - GTK file manager theming

### ⚡ Performance
- **Instant Loading** - Cached themes load in milliseconds
- **Zero Redundancy** - Same wallpaper never regenerates theme
- **Optimized Reloads** - Smart application reloading without crashes

## 📦 Installation

### Quick Install

```bash
cd ~/Projects/dotfiles
./install.sh
```

The installer will:
1. Detect your distribution (Ubuntu/Mint/Kali)
2. Install all required dependencies
3. Set up directory structure
4. Make scripts executable
5. Test the theme engine

### Manual Installation

#### Dependencies

**Required:**
- `hyprland` - Wayland compositor
- `waybar` - Status bar
- `kitty` - Terminal emulator
- `wofi` - Application launcher
- `swww` - Wallpaper daemon
- `matugen` - Color scheme generator
- `grim` + `slurp` - Screenshot tools
- `wl-clipboard` - Clipboard utilities
- `imagemagick` - Image processing
- `inotify-tools` - File system monitoring

**Ubuntu/Debian/Mint:**
```bash
sudo apt install hyprland waybar kitty wofi swww grim slurp wl-clipboard imagemagick libnotify-bin inotify-tools jq
cargo install matugen
```

**Arch/Manjaro:**
```bash
sudo pacman -S hyprland waybar kitty wofi swww grim slurp wl-clipboard imagemagick libnotify inotify-tools jq matugen
```

## 🚀 Usage

### Basic Commands

```bash
# Apply random wallpaper theme
./scripts/theme-engine.sh random

# Interactive wallpaper selection
./scripts/theme-engine.sh select

# Apply specific wallpaper
./scripts/theme-engine.sh apply /path/to/wallpaper.jpg

# List available wallpapers
./scripts/theme-engine.sh list

# Show current theme info
./scripts/theme-engine.sh current

# Clear theme cache
./scripts/theme-engine.sh clean

# Watch for new wallpapers (auto-apply)
./scripts/theme-engine.sh watch
```

### Keybindings (in Hyprland)

| Key Combination | Action |
|----------------|--------|
| `SUPER + B` | Open wallpaper selector |
| `SUPER + SHIFT + B` | Apply random wallpaper |
| `SUPER + Q` | Open terminal |
| `SUPER + R` | Application launcher |
| `SUPER + SHIFT + S` | Screenshot tool |

### Starting Hyprland

```bash
# Start Hyprland with theme engine
./run.sh
```

The theme engine will automatically:
1. Start swww daemon
2. Apply a random wallpaper on first launch
3. Load cached theme if available
4. Generate new theme if needed

## 🏗️ Architecture

### Directory Structure

```
dotfiles/
├── hypr/
│   ├── hyprland.conf      # Main Hyprland config
│   └── colors.conf        # Dynamic colors (generated)
├── waybar/
│   ├── config.jsonc       # Waybar configuration
│   ├── style.css          # Waybar styling
│   └── colors.css         # Dynamic colors (generated)
├── kitty/
│   ├── kitty.conf         # Kitty configuration
│   └── colors.conf        # Dynamic colors (generated)
├── wofi/
│   ├── config             # Wofi configuration
│   ├── style.css          # Wofi styling
│   └── colors.css         # Dynamic colors (generated)
├── matugen/
│   ├── config.toml        # Matugen configuration
│   └── templates/         # Color templates
│       ├── hyprland-colors.conf
│       ├── kitty-colors.conf
│       ├── colors.css
│       ├── wofi-colors.css
│       └── gtk-colors.css
├── scripts/
│   ├── theme-engine.sh    # Main theme engine
│   ├── wallpaper-watcher.sh
│   ├── wallpaper-selector.sh
│   └── screenshot.sh
├── wallpapers/            # Your wallpaper collection
├── themes/                # Theme cache (auto-generated)
│   └── <hash>/
│       ├── wallpaper.txt
│       ├── colors.json
│       ├── hyprland-colors.conf
│       ├── kitty-colors.conf
│       ├── waybar-colors.css
│       └── wofi-colors.css
└── gtk/
    └── colors.css         # GTK theming (generated)
```

### Theme Caching System

1. **Hash Generation** - MD5 hash of wallpaper file
2. **Cache Check** - Looks for existing theme in `themes/<hash>/`
3. **Cache Hit** - Loads pre-generated configs instantly
4. **Cache Miss** - Generates new theme and caches it
5. **Validation** - Verifies all configs before applying

### Color Generation Flow

```
Wallpaper → Matugen → Templates → Configs → Validation → Apply → Reload
```

## 🎨 Customization

### Adding New Wallpapers

```bash
# Simply copy wallpapers to the wallpapers directory
cp /path/to/image.jpg ~/Pictures/Wallpapers/

# If watcher is running, theme applies automatically
# Otherwise, apply manually:
./scripts/theme-engine.sh apply ~/Pictures/Wallpapers/image.jpg
```

### Modifying Templates

Edit templates in `matugen/templates/` to customize color application:

```bash
# Example: Edit Hyprland colors template
nano matugen/templates/hyprland-colors.conf

# After editing, clear cache and regenerate
./scripts/theme-engine.sh clean
./scripts/theme-engine.sh random
```

### Adjusting Hyprland Appearance

Edit `hypr/hyprland.conf` to modify:
- Window gaps and padding
- Border sizes
- Blur and transparency
- Animations
- Keybindings

## 🐛 Debugging

### Log Files

```bash
# View theme engine logs
tail -f ~/.cache/theme-engine.log

# View wallpaper watcher logs
tail -f ~/.cache/wallpaper-watcher.log
```

### Common Issues

**Theme not applying:**
```bash
# Check if swww daemon is running
pgrep swww-daemon

# Restart swww
killall swww-daemon
swww-daemon &
```

**Colors not updating:**
```bash
# Clear cache and regenerate
./scripts/theme-engine.sh clean
./scripts/theme-engine.sh random

# Reload Hyprland
hyprctl reload
```

**Matugen errors:**
```bash
# Test matugen directly
matugen image wallpapers/your-wallpaper.jpg -j hex

# Check matugen config
cat matugen/config.toml
```

## 🔧 Advanced Features

### Auto-Detection Mode

Run the watcher in the background:

```bash
# Start watcher
./scripts/theme-engine.sh watch &

# Or add to Hyprland autostart
exec-once = ~/.config/hypr/scripts/wallpaper-watcher.sh
```

### Systemd Service (Optional)

Create `~/.config/systemd/user/wallpaper-watcher.service`:

```ini
[Unit]
Description=Wallpaper Directory Watcher
After=graphical-session.target

[Service]
Type=simple
ExecStart=/home/deval/Projects/dotfiles/scripts/wallpaper-watcher.sh
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable:
```bash
systemctl --user enable --now wallpaper-watcher.service
```

## 📊 Performance Metrics

- **Cache Hit**: ~50ms (instant load)
- **Cache Miss**: ~2-3s (theme generation)
- **Wallpaper Transition**: ~1s (smooth fade)
- **Application Reload**: ~500ms (seamless)

## 🤝 Contributing

Feel free to:
- Add new templates
- Improve color schemes
- Add support for more applications
- Report bugs and issues

## 📝 License

MIT License - Feel free to use and modify

## 🙏 Credits

- **Hyprland** - Amazing Wayland compositor
- **Matugen** - Material You color generation
- **swww** - Smooth wallpaper transitions
- Community wallpapers and themes

---

**Made with ❤️ for the Linux ricing community**

