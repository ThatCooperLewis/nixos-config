These are my dotfiles. There are many like them, but these are mine.

### Overview:
- NixOS as pure as possible
- A lush Plex stack running via Nix containers (docker backend, nvidia transcode)
- Hyprland desktop with a custom theme 
- Nvidia Multi-GPU support
- KVM Passthrough

### Hardware:
- Ryzen 5950X - 16C32T
- Nvidia 3080 10GB (provided to KVM for gaming)
- Nvidia 1080 8GB (provided to containers for transcode)
- 64 GB CL16 3600MT/s RAM
- 4TB SSD storage

Also patched into this config is a TrueNAS machine:
- Intel 8700k - 6C12T
- 32GB 3200MT/s RAM
- 100TB raw, 60TB usable storage

I've included URL sources for any odd/unique config choices I've made along the way.