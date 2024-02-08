{ config, constants, ... }:
/*

Uptime Kuma, a clean webUI for public monitoring the plex stack
https://github.com/louislam/uptime-kuma

*/
let 
  docker = constants.docker;
in
{
  config.virtualisation.oci-containers.containers = {
    palworld = {
      image = "thijsvanloef/palworld-server-docker:latest";
      ports = docker.ports.palworld;
      environment = {
        PUID = docker.users.palworld;
        PGID = docker.users.palworld;
        PORT = "${toString docker.ports.palworld}";
        PLAYERS = "16";
        MULTITHREADING = "false";
        COMMUNITY = "false";
        PUBLIC_IP = "***REMOVED***";
        # SERVER_PASSWORD = "***REMOVED***";
        # SERVER_NAME = "Pals Together Strong";
        # ADMIN_PASSWORD = "***REMOVED***";
      };
      volumes = [
        "${docker.dirs.palworld}:/palworld/"
      ];
    };
  };
}