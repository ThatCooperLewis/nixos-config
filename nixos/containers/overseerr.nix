{ config, constants, ... }:

##########################
####### OVERSEERR ########
##########################

/*

Separating the public requests site from the NUC's plex stack, so it can be isolated from the rest of the network

*/

let
  
  docker = constants.docker;

in {

  config.networking.firewall.allowedTCPPorts = [ constants.ports.overseerr ];
  config.users.users.overseerr = {
    uid = constants.users.multimedia;
    description = "Overseerr";
    isSystemUser = true;
    group = "overseerr";
    extraGroups = [ "wheel" ];
  };
  config.users.groups.overseerr.gid = constants.users.multimedia;

  config.virtualisation.oci-containers.containers.overseerr = {
    image = "ghcr.io/hotio/overseerr";
    ports = docker.ports.overseerr;
    environment = docker.environment;
    volumes = [
      "/var/lib/overseerr:/config"
    ];
  };
}
    
    