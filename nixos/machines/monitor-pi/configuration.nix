{ config, pkgs, lib, inputs, ... }:

let
  user = "cooper";
  hostname = "monitor-pi";
in {

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware.enableRedistributableFirmware = true;
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = hostname;
  };

  environment.systemPackages = with pkgs; [
    micro
    git
    wget
    curl
    libraspberrypi
    openssh
    btop
    home-manager
    neofetch
  ];

  time.timeZone = "America/Los_Angeles";

  services.openssh.enable = true;
  
  users = {
    mutableUsers = true;
    users.cooper = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  system.stateVersion = "23.11";
}
