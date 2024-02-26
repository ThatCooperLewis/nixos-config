#! /usr/bin/env bash

# Wallpaper daemon
swww init &
# Set wallpaper
swww img /home/cooper/.config/wallpaper/wallpaper.jpg &

# Network manager
nm-applet --indicator

# Taskbar
# waybar 

# Notifs
# dunst
