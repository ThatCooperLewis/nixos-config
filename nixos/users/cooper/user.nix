{ config, pkgs, inputs, constants, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.cooper = import ./home.nix;

  programs.zsh.enable = true;

  users.users.cooper = {
    openssh.authorizedKeys.keys = [
      constants.sshKeys.macbook
      constants.sshKeys.nuc
    ];
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Cooper Lewis";
    extraGroups = [ "docker" "wheel" "networkmanager" ];
  };
}  