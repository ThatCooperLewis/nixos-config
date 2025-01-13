{ config, constants, ... }:
/*

Uptime Kuma, a clean webUI for public monitoring the plex stack
https://github.com/louislam/uptime-kuma

*/

{
  config.networking.firewall.allowedTCPPorts = [ constants.ports.uptime ];
  
  config.users.users.uptime = {
    uid = constants.users.uptime;
    description = "Uptime Kuma";
    isNormalUser = false;
    group = "uptime";
    extraGroups = [ "wheel" ];
  };
  config.users.groups.uptime.gid = constants.users.uptime;

  config.virtualisation.oci-containers.containers = {
   uptime = {
      image = "louislam/uptime-kuma:latest";
      ports = constants.docker.ports.uptime;
      environment = {
      	PUID = constants.docker.users.uptime;
      	PGID = constants.docker.users.uptime;
      };
      volumes = ["${constants.docker.dirs.uptime}/config:/app/data"];
    };
  };
}