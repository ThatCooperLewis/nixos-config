{ pkgs, inputs, constants, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ../home-network.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  homeNetwork = {
    enable = true;
    address = "10.0.50.1";
    interface = "enp8s0";
    hostname = "nix-brain";
  };

  ### Locale
  time.timeZone = constants.systemDefaults.timeZone;
  i18n.defaultLocale = constants.systemDefaults.defaultLocale;
  i18n.extraLocaleSettings = constants.systemDefaults.extraLocaleSettings;

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
    cowsay
    restic
    pipes
    python3
    inputs.fix-python
    unclutter
    nixos-generators
  ];

  system.stateVersion = "24.11";
}