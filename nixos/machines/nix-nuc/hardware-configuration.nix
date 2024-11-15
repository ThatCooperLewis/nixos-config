{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  # Resolve tdarr/quicksync error https://www.reddit.com/r/jellyfin/comments/ulw3ct/comment/i87o67b/
  boot.kernelParams = [ "i915.enable_guc=2" ]; 
  boot.extraModulePackages = [ ];
  # Allow for cross-compiling Nix builds to Raspberry Pi's
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Enable VAAPI / Quicksync for transcode work
  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/bbce77f5-91bf-48ed-87e0-adc75bd566a4";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0AD5-84A1";
      fsType = "vfat";
    };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 16*1024;
  } ];

  # NAS Remote Drives

  # fileSystems."/mnt/primary-backup" =
  #   { device = "10.0.50.2:/mnt/tahani/primary-backup";
  #     fsType = "nfs";
  #   };

  fileSystems."/mnt/plex-content-4k" =
    { device = "10.0.50.2:/mnt/tahani/data-4k";
      fsType = "nfs";
    };

  fileSystems."/mnt/plex-content" =
    { device = "10.0.50.2:/mnt/tahani/data";
      fsType = "nfs";
    };

  fileSystems."/mnt/plex-downloads" =
    { device = "10.0.50.2:/mnt/tahani/escrow-data/plex";
      fsType = "nfs";
    };
# 
  fileSystems."/mnt/nas-tdarr" =
    { device = "10.0.50.2:/mnt/apps/tdarr";
      fsType = "nfs";
    };

  networking.hostName = "nix-nuc";
  networking.networkmanager.enable = true;
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
