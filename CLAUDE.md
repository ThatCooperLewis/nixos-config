# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Deploy Commands

All Nix configuration lives under `nixos/`. The flake must be referenced from that directory.

**Rebuild a NixOS machine:**
```bash
sudo nixos-rebuild switch --flake ~/nixos-config/nixos#<hostname>
```

**Rebuild a macOS (Darwin) machine:**
```bash
sudo nix run nix-darwin -- switch --flake ~/nixos-config/nixos
```

**Update flake inputs:**
```bash
nix flake update --flake ~/nixos-config/nixos
```

**Check flake validity:**
```bash
nix flake check ~/nixos-config/nixos
```

Valid hostnames: `nix-nuc`, `nix-brain`, `nix-game`, `nix-remote`, `cooper-mbp`, `adguard-pi`, `caddy-pi`, `cloudflare-fallback-pi`, `fortress-pi`

## Architecture

### Flake Structure

The flake (`nixos/flake.nix`) tracks **NixOS 25.11** stable with an unstable channel available. It produces:
- `darwinConfigurations`: 1 macOS machine (aarch64-darwin)
- `nixosConfigurations`: 8 NixOS machines (x86_64-linux + aarch64-linux RPis) + 1 ISO template

Key inputs beyond nixpkgs: `home-manager`, `chaotic` (bleeding-edge pkgs for gaming), `nix-citizen`/`nix-gaming` (Star Citizen), `vscode-server`, `claude-code`, `nix-darwin`.

### Configuration Layering

Each machine is composed in `flake.nix` by stacking modules:
1. **Machine config** (`machines/<name>/configuration.nix`) — hardware, boot, networking
2. **User configs** (`users/cooper/user.nix`, `users/root/ssh.nix`) — home-manager profiles
3. **Containers** (`containers/*.nix`) — Docker/OCI services (arr-stack, grafana, caddy, etc.)
4. **Services** (`services/*.nix`) — systemd services (tailscale, telegraf, influxdb, etc.)
5. **Flake modules** — vscode-server, chaotic, claude-code overlays

### Constants (`nixos/constants.nix`)

Central source of truth for the entire homelab. Contains:
- Static IPs and Tailscale IPs for all machines
- Service port numbers, user/group IDs
- SSH public keys for all hosts
- NFS mount paths (secrets, media, backups from TrueNAS at 10.0.50.2)
- Docker container configuration (images, volumes, env vars)

**When adding a new service or machine, update constants.nix first.**

### Raspberry Pi Pattern

All Pi machines share `machines/pi-base.nix` and are configured via options:
```nix
raspberryPi.enable = true;
raspberryPi.hostname = "name-pi";
raspberryPi.address = "10.0.50.XX";
```

### Container Pattern

Containers use `virtualisation.oci-containers.containers` with Docker backend. The arr-stack (`containers/arr-stack.nix`) is the largest, running ~10 media services. Container networking, volumes, and env vars are defined in `constants.nix`.

### Network Layout

- LAN: `10.0.50.x` (servers), `10.0.100.x` (Pi DNS)
- Tailscale VPN: `100.x.x.x`
- NFS storage: TrueNAS at `10.0.50.2`
- External access via Cloudflare tunnel through caddy-pi

## Key Machines

| Machine | Role | Notable |
|---------|------|---------|
| nix-nuc | Arr-stack media server | Intel iGPU transcode, NFS mounts |
| nix-brain | Monitoring/utility | Dual Nvidia GPUs, Grafana/InfluxDB |
| nix-game | Gaming workstation | KDE Plasma, GPU passthrough, Star Citizen |
| nix-remote | Remote server | AdGuard, lightweight |
