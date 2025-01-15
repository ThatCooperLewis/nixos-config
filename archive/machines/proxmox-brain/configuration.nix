{ config, lib, pkgs, inputs, constants, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  ### Locale
  time.timeZone = constants.systemDefaults.timeZone;
  i18n.defaultLocale = constants.systemDefaults.defaultLocale;
  i18n.extraLocaleSettings = constants.systemDefaults.extraLocaleSettings;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "proxmox-brain"; 
  networking.useDHCP = lib.mkDefault true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    micro
    curl
    wget
    btop
    home-manager
    neofetch
    vscode
    python3
    influxdb
    unclutter
    nixos-generators
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  programs.zsh.enable = true;

  system.stateVersion = "24.11";
}