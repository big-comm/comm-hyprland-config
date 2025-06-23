#!/usr/bin/env bash
CONFIG_DIR="$HOME/.config/hypr/conf/decorations"
TARGET="$CONFIG_DIR/rounding-more-blur.conf"
BLUR="$CONFIG_DIR/rounding-more-blur-full.conf"
NO_BLUR="$CONFIG_DIR/no-rounding-more-blur.conf"
# Check if blur is currently disabled (by checking for rounding = 0)
if grep -q 'rounding = 0' "$TARGET"; then
    # Enable blur (copy full blur config)
    cp -f "$BLUR" "$TARGET"
    notify-send "Hyprland" "Blur enabled"
else
    # Disable blur (copy no blur config)
    cp -f "$NO_BLUR" "$TARGET"
    notify-send "Hyprland" "Blur disabled"
fi