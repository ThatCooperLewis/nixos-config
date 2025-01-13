{ config, lib, pkgs, inputs, constants, ... }:

let 
  system = "x86_64-linux";
  bridgeNIC = "enp8s0";
  hostNIC = "enp7s0";
in {

  services.proxmox-ve = {
    enable = true;
    ipAddress = "10.0.50.1";
  };

  nixpkgs.overlays = [
    inputs.proxmox-nixos.overlays.${system}
  ];

  networking.bridges.vmbr0 = {
    interfaces = [ bridgeNIC ];  # Attach bridge to enp8s0
  };
}