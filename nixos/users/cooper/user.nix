{ config, pkgs, inputs, lib, constants, ... }:

let
  isMacOS = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.cooper = import ./home.nix;

  programs.fish.enable = true;
  programs.zsh.enable = true;
  services.openssh.enable = true;

  users.users.cooper = if isMacOS then {
    
    # macOS User
    name = "cooper";
    home = "/Users/cooper"; } else {
    
    # Linux User
    openssh.authorizedKeys.keys = constants.sshKeys;
    shell = pkgs.fish;
    isNormalUser = true;
    description = "Cooper Lewis";
    extraGroups = [ "docker" "wheel" "networkmanager" ]; };
}  