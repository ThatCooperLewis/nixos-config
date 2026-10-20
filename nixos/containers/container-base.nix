{ config, pkgs, lib, constants, ... }:
/*

Default configuration to enable docker containers on a machine.
Use in conjunction with an actual container.

*/
{
  config.networking.firewall = {
    enable = true;
    interfaces.docker1 = {
      # Allow containers to query each other
      allowedUDPPorts = [ 53 ];
    };
  };

  # Install docker
  config.virtualisation.docker = {
  	enable = true;
  	enableOnBoot = true;
  	rootless = {
  	  enable = true;
  	  setSocketVariable = true;	
  	};
  };

  config.virtualisation.oci-containers.backend = "docker";
  # Emit docker metrics to telegraf, which needs the docker socket to read them
  config.services.telegraf.extraConfig.inputs.docker = {};
  # mkIf on the whole attrset, so machines without telegraf don't get an empty telegraf user
  config.users.users = lib.mkIf config.services.telegraf.enable {
    telegraf.extraGroups = [ "docker" ];
  };
}