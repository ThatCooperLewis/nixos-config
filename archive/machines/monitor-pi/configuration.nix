{ config, pkgs, lib, inputs, constants, ... }:

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
    tmux
    home-manager
    neofetch
  ];

  time.timeZone = "America/Los_Angeles";

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  
  users = {
 
    mutableUsers = true;
    users= {

      root = {
        openssh.authorizedKeys.keys = [
          # Primary machine
      	  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFc7oy576jPgeUwNrOyoPIC/4pyQDwEFiqy9cL0fxjx9 thatcooperlewis@gmail.com"
      	  # Nix NUC
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILJ6iW/l9eTDYdGO80t/witkAPrUtUsUcQildOoHJwUX thatcooperlewis@gmail.com"
        ];
      };
    
      cooper = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      uptime = {
      	uid = constants.users.uptime;
      	description = "Uptime Kuma";
      	isNormalUser = false;
      	group = "uptime";
      	extraGroups = [ "wheel" ];
      };	
    };
    groups.uptime.gid = constants.users.uptime;

  };

  # Define hostname for telegraf
  services.telegraf.extraConfig = {
    agent.hostname = "monitor-pi";
    inputs.http_response.urls = [ 
      constants.urls.plex
      constants.urls.tdarr
      constants.urls.overseerr
      constants.urls.sab
      constants.urls.radarr
      constants.urls.sonarr
      constants.urls.ha
      constants.urls.octopi
      constants.urls.uptime
    ];
  };

  system.stateVersion = "23.11";
}
