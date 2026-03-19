#!/bin/bash

# Folder
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

# Filename with timestamp
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Take screenshot → save + clipboard
grim -g "$(slurp)" - | tee "$FILE" | wl-copy

# Optional: notification
notify-send "Screenshot taken" "Saved to $FILE and copied to clipboard"
