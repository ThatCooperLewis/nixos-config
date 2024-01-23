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

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 8*1024;
  } ];

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
    users= {
      cooper = {
        isNormalUser = true;
        extraGroups = [ "wheel" "tig" ];
      };

      tig = {
        uid = 950;
        description = "Telegraf/Influx/Grafana Monitoring";
      	isNormalUser = false;
      	group = "tig";
      	extraGroups = [ "wheel" ];
      };

      uptime = {
      	uid = 900;
      	description = "Uptime Kuma";
      	isNormalUser = false;
      	group = "uptime";
      	extraGroups = [ "wheel" ];
      };	
    };
    groups.tig.gid = 950;
    groups.uptime.gid = 900;

  };

  system.stateVersion = "23.11";
}
