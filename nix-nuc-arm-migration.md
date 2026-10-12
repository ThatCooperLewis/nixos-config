# nix-nuc → ARM (aarch64-linux) Migration Audit

Full compatibility audit of the `nix-nuc` NixOS configuration for migration from `x86_64-linux` to `aarch64-linux`.

## ✅ Confirmed Available on ARM (No Changes Needed)

| Component | Source | Notes |
|-----------|--------|-------|
| `git` | nixpkgs | ✅ |
| `micro` | nixpkgs | ✅ |
| `curl` | nixpkgs | ✅ |
| `wget` | nixpkgs | ✅ |
| `btop` | nixpkgs | ✅ |
| `home-manager` | nixpkgs | ✅ |
| `neofetch` | nixpkgs | ✅ (deprecated upstream — consider `fastfetch`) |
| `cowsay` | nixpkgs | ✅ |
| `pipes` (pipes.sh) | nixpkgs | ✅ (pure shell script) |
| `python3` | nixpkgs | ✅ |
| `unclutter` | nixpkgs | ✅ |
| `nixos-generators` | nixpkgs | ✅ |
| `nodejs` | nixpkgs | ✅ |
| `bfg-repo-cleaner` | nixpkgs | ✅ (JVM-based) |
| `cargo` | nixpkgs | ✅ |
| `rustc` | nixpkgs | ✅ |
| `gcc` | nixpkgs | ✅ |
| `pkg-config` | nixpkgs | ✅ |
| `clippy` | nixpkgs | ✅ |
| `ffmpeg` | nixpkgs | ✅ |
| `rsync` | nixpkgs | ✅ (used by rsync-backup) |
| `eza`, `bat`, `ripgrep`, `fzf` | home-manager | ✅ |
| `zoxide` | home-manager | ✅ |
| `fish`, `zsh` | nixpkgs | ✅ |
| Fish plugins (fzf-fish, z, autopair, done) | nixpkgs | ✅ |
| `services.openssh` | NixOS | ✅ |
| `services.tailscale` | NixOS | ✅ Full ARM support |
| `services.nginx` | NixOS (geocities-portfolio) | ✅ |
| `virtualisation.docker` | NixOS | ✅ Docker has aarch64 support |
| NFS mounts | NixOS | ✅ Kernel-level, works on ARM |
| `systemd-boot` bootloader | NixOS | ✅ Works on ARM with UEFI |

## ⚠️ Works But Needs Changes / Attention

### 1. `vscode` (system-level package in `configuration.nix`)

**Status:** ✅ Available — VS Code has official ARM64 builds, and nixpkgs packages it for `aarch64-linux`.

**Note:** `home.nix` already **disables VS Code extension management** on ARM:

```nix
supportsCode = pkgs.stdenv.hostPlatform.system != "aarch64-linux";
```

The system-level `pkgs.vscode` in `configuration.nix` will still install, but the home-manager extensions block will be skipped. The extensions used (Copilot, GitLens, Python, etc.) do have ARM64 builds on the marketplace, so you could remove that guard if desired.

### 2. `claude-code` (from `sadjow/claude-code-nix`)

**Status:** ⚠️ **Needs verification.** Claude Code is a Node.js CLI tool (npm package), so it's inherently cross-platform. However, the Nix flake at `github:sadjow/claude-code-nix` must explicitly declare `aarch64-linux` in its supported systems. Verify by running:

```bash
nix eval github:sadjow/claude-code-nix#packages.aarch64-linux.claude-code --json
```

### 3. `vscode-server` (from `nix-community/nixos-vscode-server`)

**Status:** ⚠️ **Likely works.** This NixOS module patches the VS Code Server binary (the remote component) to run on NixOS. Microsoft provides ARM64 VS Code Server builds, and the module dynamically patches whatever binary is downloaded. Should work on `aarch64-linux`, but test it.

### 4. `inputs.fix-python` (from `GuillaumeDesforges/fix-python`)

**Status:** ⚠️ **Needs verification.** This is used directly as a system package. Check whether the flake's default package supports `aarch64-linux`:

```bash
nix eval github:GuillaumeDesforges/fix-python#packages.aarch64-linux.default --json
```

### 5. `services.xserver` with display/desktop

**Status:** ⚠️ **Works, but video drivers need changing.** XFCE and LightDM are available on ARM. However, the current config uses:

```nix
videoDrivers = [ "qxl" "virtio" ];
```

These are **QEMU virtual display drivers**. If the ARM machine is a bare-metal device, replace these with appropriate drivers (e.g., `modesetting` for most ARM SoCs, or a specific GPU driver). If it's still a QEMU/KVM VM, `virtio` should work on ARM QEMU.

### 6. `services.spice-vdagentd`

**Status:** ⚠️ **Only relevant in a SPICE/QEMU VM.** Available on ARM in nixpkgs, but pointless on bare metal. Remove if migrating to physical hardware.

### 7. Docker images — arr-stack containers

Most images are multi-arch, but verify these specifically:

| Image | ARM64 Status |
|-------|-------------|
| `kometateam/kometa` | ✅ Multi-arch (Python-based) |
| `ghcr.io/hotio/bazarr` | ✅ hotio provides `linux/arm64` |
| `ghcr.io/hotio/prowlarr` | ✅ hotio provides `linux/arm64` |
| `ghcr.io/hotio/radarr:release` | ✅ hotio provides `linux/arm64` |
| `ghcr.io/hotio/sonarr:release` | ✅ hotio provides `linux/arm64` |
| `ghcr.io/hotio/lidarr` | ✅ hotio provides `linux/arm64` |
| `ghcr.io/tautulli/tautulli` | ✅ Multi-arch (Python-based) |
| `darkalfx/requestrr` | ⚠️ **Likely x86-only.** This .NET-based image may not have arm64 builds. Check Docker Hub or consider the fork `thomst08/requestrr` which may have multi-arch. |
| `ghcr.io/haveagitgat/tdarr:latest` | ⚠️ **Verify.** Tdarr has added ARM support but it's been inconsistent. Check their GHCR tags for `linux/arm64` manifests. |
| `ghcr.io/haveagitgat/tdarr_node:latest` | ⚠️ **Same as above.** Additionally, `--device=/dev/dri` GPU passthrough requires the ARM device to have a DRI-capable GPU. Intel QuickSync won't exist on ARM. |

### 8. Stubert service

**Status:** ⚠️ The systemd service itself is fine, but the Rust binary at `/home/cooper/Development/stubert/target/release/stubert` will need to be **recompiled for aarch64**. The Cargo/Rust toolchain is available on ARM, so just run `cargo build --release` on the new system.

## ❌ Must Remove or Replace (x86-Specific)

### 1. `intel-gpu-tools`

**Why:** Intel GPU management tools. Useless without Intel hardware. While it may technically compile on ARM, it serves no purpose.

**Action:** Remove from `environment.systemPackages`.

### 2. `boot.initrd.kernelModules = [ "kvm-intel" ]`

**Why:** Intel KVM virtualization module doesn't exist on ARM.

**Action:** Remove or replace with `kvm` (generic) if running on ARM hardware with KVM support.

### 3. `boot.kernelParams = [ "i915.enable_guc=2" ... ]`

**Why:** `i915.enable_guc=2` is Intel integrated GPU specific. The ZFS param is fine if ZFS is still used.

**Action:** Remove `i915.enable_guc=2`. Keep ZFS param only if needed.

### 4. `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`

**Why:** This enables x86 machines to emulate ARM. On an ARM machine, you're already native.

**Action:** Remove entirely (or change to `[ "x86_64-linux" ]` if you want to emulate x86 on ARM).

### 5. `nixpkgs.hostPlatform = "x86_64-linux"`

**Why:** Declares x86 architecture.

**Action:** Change to `"aarch64-linux"`.

### 6. Hardware configuration (`hardware-configuration.nix`)

**Why:** The entire file is x86-specific — QEMU guest profile, Intel kernel modules, disk UUIDs, etc.

**Action:** Generate a **new** `hardware-configuration.nix` on the ARM device using `nixos-generate-config`.

## 📋 Summary

| Status | Count | Items |
|--------|-------|-------|
| ✅ No issues | ~30+ | Most nixpkgs packages, tailscale, nginx, docker, NFS, home-manager tools |
| ⚠️ Verify/adjust | 8 | `claude-code`, `vscode-server`, `fix-python`, video drivers, SPICE, `requestrr` image, `tdarr` images, stubert binary |
| ❌ Must change | 6 | `intel-gpu-tools`, `kvm-intel`, `i915` params, `binfmt`, `hostPlatform`, `hardware-configuration.nix` |

The biggest risks are the **third-party flake inputs** (`claude-code`, `fix-python`) which should be tested with `nix eval` for `aarch64-linux` support, and the **Docker images** (`requestrr`, `tdarr`/`tdarr_node`) which may lack ARM64 builds. Everything from core nixpkgs is well-supported on `aarch64-linux`.
