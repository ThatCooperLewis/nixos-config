{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems = {

    "/" = { 
      device = "/dev/disk/by-uuid/017ba40a-179a-4d69-94f1-82a08dff4ac9";
      fsType = "ext4";
    };

    "/boot" = { 
      device = "/dev/disk/by-uuid/EA54-CC20";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  
    "/mnt/nas-plex" = { 
      device = "10.0.50.2:/mnt/apps/plex";
      fsType = "nfs";
    };

  };


  swapDevices = [
    { device = "/dev/disk/by-uuid/012ad531-5642-477e-b77a-3a1d394bd6a7"; }
  ];

  networking.hostName = "nix-brain";
  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp8s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp6s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}