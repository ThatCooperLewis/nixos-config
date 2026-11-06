{ config, lib, pkgs, modulesPath, ... }:

# fortress-pi: Overseerr, the only homelab app the public can reach (through its own Cloudflare tunnel).
# A TrueNAS VM since 2026-11 (it was a Raspberry Pi; the hostname stayed). Its VirtIO NIC is attached to the
# NAS's spare NIC enp3s0, cabled to an untagged VLAN 60 (DMZ) switch port, so the UniFi DMZ rules isolate it
# exactly as they did the Pi. See Brain Wiki/Home Network "fortress-pi Isolation".
# Fresh install: nixos-anywhere with ./disko.nix; see Brain Projects/Hardware Consolidation Plan.
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ../home-network.nix
  ];

  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = "x86_64-linux";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Accept builds signed by nix-nuc (the build host), so deploys work as cooper with --sudo
  nix.settings.extra-trusted-public-keys = [ "nix-nuc-1:UJRsbdcJbusuHasbct8m8HWcZQpA7D/G/+pMTHFr7k4=" ];
  time.timeZone = "America/Los_Angeles";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_blk" "sr_mod" ];
  zramSwap.enable = true;

  # eth0 instead of a PCI-slot name, so the NIC name can't change when the VM's devices do
  networking.usePredictableInterfaceNames = false;
  homeNetwork = {
    enable = true;
    hostname = "fortress-pi";
    address = "10.60.0.33";
    interface = "eth0";
    # DMZ (VLAN 60), isolated by UniFi firewall rules
    gateway = "10.60.0.1";
    prefixLength = 24;
  };

  # Internet-facing: no root login. Deploy as cooper with --sudo --ask-sudo-password.
  services.openssh.settings.PermitRootLogin = lib.mkForce "no";
  # cooper's sudo password. The plaintext is secrets/fortress-pi-cooper-password.age (only Cooper's key can read it)
  age.secrets.fortress-pi-cooper-hash.file = ../../secrets/fortress-pi-cooper-hash.age;
  users.users.cooper.hashedPasswordFile = config.age.secrets.fortress-pi-cooper-hash.path;

  # The shared home-manager profile adds VS Code on every non-ARM Linux; a DMZ server doesn't need it
  home-manager.users.cooper.programs.vscode.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    micro git wget curl openssh btop tmux home-manager fastfetch python3
  ];
}
