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

Valid hostnames: `nix-nuc`, `mac-studio`, `fortress-pi`

## Troubleshooting

Write-ups of problems solved before (symptoms, root cause, manual fix) live as Markdown notes in the Obsidian vault at `~/Brain/Wiki/`. Scripts that automate those fixes live in `scripts/`. **When debugging an error, grep both for the error message first** before working out the fix from scratch.

| Script | Note | Problem |
|--------|------|---------|
| `scripts/restore-nix-darwin.sh` | `~/Brain/Wiki/macOS Migration.md` | nix-darwin Mac broken after Migration Assistant (missing `/nix`, shell won't start, installer keychain error, `/etc` conflicts) |

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

### Archive

`../archive/` (repo root) holds retired configs for reference, not built: old flake outputs in `archive/flake.nix` (including the Raspberry Pis, retired 2026-11-09), plus their machine and service modules (`archive/machines/pi-base.nix`, `archive/services/adguard.nix`).

### Container Pattern

Containers use `virtualisation.oci-containers.containers` with Docker backend. The arr-stack (`containers/arr-stack.nix`) is the largest, running ~10 media services. Container networking, volumes, and env vars are defined in `constants.nix`.

### Network Layout

- LAN: `10.0.50.x` (servers), `10.50.0.x` (Homelab VLAN), `10.60.0.x` (DMZ)
- Tailscale VPN: `100.x.x.x`
- NFS storage: TrueNAS at `10.0.50.2`
- External access via Cloudflare tunnels: the shared one on nix-nuc, Overseerr's own on fortress-pi

## Key Machines

| Machine | Role | Notable |
|---------|------|---------|
| nix-nuc | TrueNAS VM: arr-stack, Caddy, shared Cloudflare tunnel, Stubert | NFS mounts |
| fortress-pi | TrueNAS VM in the DMZ: Overseerr + its own tunnel | Name kept from the old Pi |
