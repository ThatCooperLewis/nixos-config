# nix-nuc on TrueNAS: x86_64 VM (VM "nixOS", OS zvol apps/virtual-machines/nixOS-l7w4s1),
# NIC on enp4s0 / switch port MGE9. Started from nixos-generate-config output.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "xhci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  # Resolve tdarr/quicksync error https://www.reddit.com/r/jellyfin/comments/ulw3ct/comment/i87o67b/
  boot.kernelParams = [ "i915.enable_guc=2" "zfs.zfs_arc_max=4294967296" ];
  boot.extraModulePackages = [ ];
  # Allow for cross-compiling Nix builds to Raspberry Pi's
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/5fe4f259-2905-4733-b3a1-05d237747aed";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/326D-3C99";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ 
    #{ device = "/dev/disk/by-uuid/3eacf5be-36ae-437c-827d-b45d21dc0b3b"; }
    { device = "/swapfile"; size = 20480; }
    ];

  homeNetwork.interface = "ens3";

  # Intel iGPU tools and the QEMU/SPICE display, specific to this host
  environment.systemPackages = [ pkgs.intel-gpu-tools ];
  services.xserver.videoDrivers = [ "qxl" "virtio" ];
  services.spice-vdagentd.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
