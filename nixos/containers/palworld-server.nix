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
  config = {
    networking.firewall = {
      allowedUDPPorts = portsList;
      interfaces.docker1.allowedUDPPorts = portsList;
    };

    users = {
      users.palworld = {
        uid = constants.users.palworld;
        description = "Palworld dedicated server";
        isSystemUser = true;
        group = "palworld";
        extraGroups = [ "wheel" ];
      };
      groups.palworld.gid = constants.users.palworld;
    };

    virtualisation.oci-containers.containers = {
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
  };
}