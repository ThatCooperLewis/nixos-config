{ pkgs, inputs, constants, ... }:

{

  imports = [ 
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "nix-remote";

  time.timeZone = constants.systemDefaults.timeZone;
  i18n.defaultLocale = constants.systemDefaults.defaultLocale;
  i18n.extraLocaleSettings = constants.systemDefaults.extraLocaleSettings;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    micro
    curl
    wget
    btop
    home-manager
    neofetch
    cowsay
    pipes
    python3
    inputs.fix-python
    unclutter
    nixos-generators
  ];

  system.stateVersion = "25.05";

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
}