# Hyprland + AGS Automated Theming Engine 🎨

> Production-grade, zero-bloat theming system optimized for LLM workloads with intelligent caching and dynamic color generation.

![Status](https://img.shields.io/badge/status-production-green)
![Platform](https://img.shields.io/badge/platform-Hyprland-blue)

## ✨ Stack

- **WM**: Hyprland
- **UI**: AGS (Aylur's GTK Shell)
- **Terminal**: WezTerm
- **Launcher**: Rofi
- **Notifications**: Mako
- **Lockscreen**: Hyprlock
- **Clipboard**: cliphist + rofi
- **File Manager**: Nemo (GTK)
- **Wallpaper**: swww
- **Theme Engine**: Matugen

## 🎯 Features

- **Intelligent Caching** - MD5-based, zero redundancy
- **Dynamic Colors** - Material You color extraction
- **Full Integration** - Hyprland, AGS, WezTerm, Rofi, GTK
- **Auto-Detection** - Watches wallpaper directory
- **Validation System** - Auto-validates all configs
- **LLM Optimized** - Performance mode for RAM/VRAM priority
- **Zero Bloat** - Minimal, modular, production-ready

## 📦 Installation

```bash
cd ~/Projects/dotfiles
./install.sh
```

## 🚀 Usage

```bash
# Apply random wallpaper
./scripts/theme-engine.sh random

# Apply specific wallpaper
./scripts/theme-engine.sh apply /path/to/wallpaper.jpg

# List wallpapers
./scripts/theme-engine.sh list

# Show current theme
./scripts/theme-engine.sh current

# Clear cache
./scripts/theme-engine.sh clean

# Deploy configs to ~/.config
./scripts/theme-engine.sh deploy
```

## ⚡ LLM Mode

Optimize system for LLM workloads:

```bash
# Enable LLM mode (disable blur/animations, kill browsers)
./scripts/llm_mode.sh enable

# Disable LLM mode
./scripts/llm_mode.sh disable
```

## 🏗️ Architecture

```
dotfiles/
├── ags/                    # AGS config + generated colors
├── rofi/                   # Rofi config + generated colors
├── wezterm/                # WezTerm config + generated colors
├── hypr/                   # Hyprland config + generated colors
├── gtk/                    # GTK colors
├── matugen/
│   ├── templates/          # Color templates
│   └── config.toml         # Matugen config
├── scripts/
│   ├── theme-engine.sh     # Main orchestrator
│   ├── generate_theme.sh   # Theme generation + validation
│   ├── reload.sh           # Component reloading
│   ├── llm_mode.sh         # LLM optimization
│   ├── wallpaper-watcher.sh
│   └── wallpaper-selector.sh
├── themes/                 # Cache (auto-generated)
├── wallpapers/             # Your wallpaper collection
└── logs/                   # Logs (theme.log, errors.log)
```

## 🎨 Theme Generation Flow

```
Wallpaper → Hash → Cache Check → Matugen → Validation → Deploy → Reload
```

## 🔄 Reload System

Safely reloads:
- Hyprland (hyprctl reload)
- AGS (quit + run)
- WezTerm (auto-reload)
- GTK (gsettings)

## 🧪 Validation

Automatically validates:
- Hyprland colors syntax
- AGS CSS variables
- Rofi color definitions
- WezTerm Lua syntax
- GTK color definitions

## 📊 Performance

- **Cache Hit**: ~50ms
- **Cache Miss**: ~2-3s
- **Wallpaper Transition**: ~1s
- **Component Reload**: ~500ms

## 🐛 Debugging

```bash
# View logs
tail -f logs/theme.log
tail -f logs/errors.log
```

## 🔧 Keybindings

| Key | Action |
|-----|--------|
| `SUPER + Q` | Terminal (WezTerm) |
| `SUPER + R` | Launcher (Rofi) |
| `SUPER + B` | Wallpaper selector |
| `SUPER + SHIFT + B` | Random wallpaper |
| `SUPER + W` | Reload AGS |
| `SUPER + SHIFT + S` | Screenshot |

## 📝 License

MIT License

---

**Optimized for LLM workloads | Zero bloat | Production-ready**
