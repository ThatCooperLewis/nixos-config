{ config, constants, ... }:
/*

Navidrome, a music streaming webserver
https://www.navidrome.org/docs/installation/docker/

*/

{
  config.networking.firewall.allowedTCPPorts = [ constants.ports.navidrome ];
  
  config.users.users.navidrome = {
    uid = constants.users.navidrome;
    description = "Navidrome Music";
    isNormalUser = false;
    group = "navidrome";
    extraGroups = [ "wheel" ];
  };
  config.users.groups.navidrome.gid = constants.users.navidrome;
  
  config.virtualisation.oci-containers.containers = {
   navidrome = {
      image = "deluan/navidrome:latest";
      ports = constants.docker.ports.navidrome;
      environment = {
      	PUID = constants.docker.users.navidrome;
      	PGID = constants.docker.users.navidrome;
      };
      volumes = [
        "${constants.docker.dirs.navidrome}/data:/data"
        "${constants.docker.dirs.navidrome}/music:/music:ro"
        "${constants.docker.dirs.navidrome}/cache:/cache"
      ];
    };
  };
}
