{ config, options, lib, pkgs, ... }:

############################
####### Raspberry Pi #######
############################

/*

This configuration is shared between all Rasbperry Pi's in this network.
It assumes you installed NixOS on a Pi 4, using the official ISO (otherwise the NIXOS_SD filesystem may have a different name).
Hostname and Memory Swap are configurable. 

Example usage inside a machine's flake:

  modules = [
    ./machines/pi-base.nix
    {
      raspberryPi.enable = true;
      raspberryPi.hostname = "cloudflare-fallback-pi";
      raspberryPi.swapSize = 16;
    }

*/

let
  cfg = config.raspberryPi;
in
{

  imports = [
    ./home-network.nix
  ];

  options.raspberryPi = {
    enable = lib.mkEnableOption "Enable the Raspberry Pi configuration";
    hostname = lib.mkOption {
      type = lib.types.str;
      example = "my-custom-pi";
      description = "Hostname of the Raspberry Pi.";
    };
    address = lib.mkOption {
      type = lib.types.str;
      example = "10.0.99.99";
      description = "The static IP address for the machine (required)";
    };
    swapSize = lib.mkOption {
      type = lib.types.int;
      default = 16;
      description = ''
        Swap size for the Raspberry Pi (GiB).
      '';
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "23.11";
      description = "NixOS state version";
    };
  };

  config = lib.mkIf cfg.enable {
    
    system.stateVersion = cfg.stateVersion;
    nixpkgs.hostPlatform = "aarch64-linux";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    time.timeZone = "America/Los_Angeles";
    hardware.enableRedistributableFirmware = true;

    homeNetwork = {
      enable = true;
      address = cfg.address;
      hostname = cfg.hostname;
      interface = "end0";
    };

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_rpi4; # Needed to boot via USB drive
      initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };


    swapDevices = [ {
      device = "/var/lib/swapfile";
      size = cfg.swapSize * 1024;
    } ];

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
  };
}