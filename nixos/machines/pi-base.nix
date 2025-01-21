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

{

  options.raspberryPi = {
    enable = lib.mkEnableOption "Enable the Raspberry Pi configuration";
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      example = "my-custom-pi";
      description = ''
        Hostname of the Raspberry Pi.
      '';
    };
    swapSize = lib.mkOption {
      type = lib.types.int;
      default = 16; # in GB or some unit you decide
      description = ''
        Swap size for the Raspberry Pi (e.g., in GiB).
      '';
    };
  };

  config = lib.mkIf config.raspberryPi.enable {
    
    nixpkgs.hostPlatform = "aarch64-linux";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.stateVersion = "23.11";

    time.timeZone = "America/Los_Angeles";
    hardware.enableRedistributableFirmware = true;
    networking.hostName = config.raspberryPi.hostname;

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
      size = config.raspberryPi.swapSize * 1024;
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