

##########################
####### NIX SQUARE #######
##########################

/*

Personal configuration for my work computer @ Square.
This is designed to avoid conflicts with our internal package manager, 
so it's missing typically-essential pkgs and cfgs

Setup via instructions here:
https://nixcademy.com/2024/01/15/nix-on-macos/

*/

{ pkgs, self, ... }: 

{

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";

  environment.systemPackages = with pkgs; [ 
    micro
    obsidian
    home-manager
  ];

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    screencapture.location = "~/Documents/screenshots";
  };

  users.users.cooperl.home = "/Users/cooperl";

  # Touch ID support for sudo
  security.pam.enableSudoTouchIdAuth = true;

  environment.etc.bashrc.target = "bashrc_nix";
  environment.etc.zshrc.target = "zshrc_nix";
  environment.etc.zshenv.target = "zshenv_nix";
  
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 5;

}