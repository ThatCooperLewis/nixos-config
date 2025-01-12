{ config, modulesPath, pkgs, lib, inputs, constants, ... }:

let
  hostname = "fortress-pi";
in {

  nixpkgs.hostPlatform = "aarch64-linux";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4; # Needed to boot via USB drive
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
    size = 16*1024;
  } ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = hostname;

  environment.systemPackages = with pkgs; [
    micro
    btop
    home-manager
    neofetch
  ];

  time.timeZone = "America/Los_Angeles";

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  users = {
    mutableUsers = true;
    users= {
      cooper = {
        openssh.authorizedKeys.keys = [
          # Personal MacBook
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrNKgFiKkwyNj0U340/9cUTi0uaRf65EMlJn0O0mM6y nix-ssh-key"
          # NUC Root
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr71CE+bzLkDKdvL7iBU/gETtgMNOK449EQl9JcDokd nix-nuc-root"
        ];
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      root.openssh.authorizedKeys.keys = [
        # NUC Root
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr71CE+bzLkDKdvL7iBU/gETtgMNOK449EQl9JcDokd nix-nuc-root"
      ];
    };
  };

  system.stateVersion = "23.11";
}