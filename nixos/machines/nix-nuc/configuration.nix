{ pkgs, inputs, constants, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ../home-network.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  homeNetwork = {
    enable = true;
    address = constants.ips.nuc;
    hostname = "nix-nuc";
    interface = "enp0s20f0u1";
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
    restic
    home-manager
    neofetch
    intel-gpu-tools
    vscode
    cowsay
    pipes
    python3
    inputs.fix-python
    unclutter
    nixos-generators
  ];

  system.stateVersion = "23.11";
}