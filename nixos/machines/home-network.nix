{ config, options, lib, pkgs, ... }:

############################
####### Home Network #######
############################

/*

This configuration is shared between all machines. 
Use this to define a static IP for the computer, so it doesn't need to be set by the Firewall/DHCP

Example usage inside a machine's flake:

  imports = [ 
    ../home-network.nix
  ];
  homeNetwork = {
    enable = true;
    address = "10.0.50.1";
    interface = "enp8s0";
    hostname = "nix-brain";
  };

Did you break a system by using the wrong interface? Use these commands to declare a static IP temporarily:

    sudo -s
    ip link                                 # Find the right interface
    ip link set dev int0s0 up               # Replace "int0s0" with your interface
    ip addr add 192.168.1.10/24 dev int0s0
    ip route add default via 192.168.1.1

*/

let 
  cfg = config.homeNetwork;
in
{
  options.homeNetwork = {
    enable = lib.mkEnableOption "Enable static IP configuration for the home network.";
    address = lib.mkOption {
      type = lib.types.str;
      example = "10.0.99.99";
    };
    interface = lib.mkOption {
      type = lib.types.str;
      example = "enp8s0";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      example = "nix-machine";
    };
  };

# Test 12
  config = lib.mkIf config.homeNetwork.enable {
    networking = {
      hostName = cfg.hostname;
      useDHCP = false;
      interfaces.${cfg.interface}.ipv4.addresses = [
        {
          address = cfg.address;
          prefixLength = 16;
        }
      ];
      defaultGateway = "10.0.30.30";
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}