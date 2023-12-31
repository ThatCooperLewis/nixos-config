# Cooper's NixOS Configs


## NixOS + Hyprland + Nvidia Multi-GPU + KVM Passthrough
*or, a masochist's wet dream*

This is a collection of my config files to get a very pretty (and powerful) installation of NixOS running on my Nvidia-heavy home server. 

The goals I've set for myself are:
- NixOS installed as purely as possible
- My Plex stack running in its various Docker containers, with nvidia hardware-acceleration for my transcode containers, configured via Nix
- Aesthetically-pleasing Hyprland desktop with functional Electron apps
- Multi-GPU support for my RTX 3080 and GTX 1080
- KVM Passthrough for gaming on a windows installation, either directly or via Looking Glass (depending on whether I want G-Sync)

I've included URL sources for any odd/unique config choices I've made along the way.