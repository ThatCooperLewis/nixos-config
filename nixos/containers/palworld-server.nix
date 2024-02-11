{ config, constants, ... }:
/*

Uptime Kuma, a clean webUI for public monitoring the plex stack
https://github.com/louislam/uptime-kuma

*/
let 
  docker = constants.docker;
  portsList = [
    constants.ports.palworld 
    constants.ports.palworldSecondary
  ];
in
{
  config.networking.firewall.allowedUDPPorts = portsList;
  config.networking.firewall.interfaces.docker1.allowedUDPPorts = portsList;
  
  config.virtualisation.oci-containers.containers = {
    palworld = {
      image = "thijsvanloef/palworld-server-docker:latest";
      ports = docker.ports.palworld;
      environment = {
        PUID = docker.users.palworld;
        PGID = docker.users.palworld;
        PORT = "${toString constants.ports.palworld}";
        PLAYERS = "16";
        MULTITHREADING = "false";
        COMMUNITY = "false";
        PUBLIC_IP = "67.160.136.187";
        # SERVER_PASSWORD = "mitcheatsass";
        # SERVER_NAME = "Pals Together Strong";
        # ADMIN_PASSWORD = "mitcheatsass_admin";
      };
      volumes = [
        "${docker.dirs.palworld}:/palworld/"
      ];
    };
  };
}