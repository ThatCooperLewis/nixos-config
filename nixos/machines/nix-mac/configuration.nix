{ pkgs, ... }:

{

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;
  
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [ 
    micro
    home-manager
  ];

  system.primaryUser = "cooper";
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
  };

  # Not sure if these do anything, but running this will for sure set the default: 
  # chsh -s /run/current-system/sw/bin/fish
  programs.fish.enable = true;
  users.users.cooper.shell = "/run/current-system/sw/bin/fish";
  environment.shells = [ "/run/current-system/sw/bin/fish" ];

  # Touch ID support for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}