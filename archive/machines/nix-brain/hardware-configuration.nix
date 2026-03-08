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
  # Allow for cross-compiling Nix builds to Raspberry Pi's
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR thatcooperlewis@gmail.com
      ARRAY /dev/md0 level=raid1 num-devices=2 UUID=32eb1e2a:752a8904:2b3dceb1:a3f82744 devices=/dev/sda,/dev/nvme2n1
    '';
  };

  environment.systemPackages = with pkgs; [
    mdadm
  ];

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

    # [460 GB] Critical data storage
    "/mnt/local-raid" = {
      device = "/dev/md0";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
    };

    # [1 TB] non-redundant data for Plex movie/show mirror
    "/mnt/local-mass" = {
      device = "/dev/sdb";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];    
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