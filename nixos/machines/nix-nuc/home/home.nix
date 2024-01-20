{ config, pkgs, ... }:

{
  # imports = [];

  home.username = "cooper";
  home.homeDirectory = "/home/cooper";

  home.stateVersion = "23.11";

  home.file = {};

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.git = {
  	enable = true;
  	userName = "Cooper Lewis";
  	userEmail = "thatcooperlewis@gmail.com";
  };
}
