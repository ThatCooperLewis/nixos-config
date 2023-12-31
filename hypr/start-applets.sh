#! /usr/bin/env bash

# Wallpaper daemon
swww init &
# Set wallpaper
swww img ~/Wallpapers/kalalau.jpg &

# Network manager
nm-applet --indicator &

# Taskbar
waybar &

# Notifs
dunst
