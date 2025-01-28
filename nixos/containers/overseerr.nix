{ config, constants, ... }:

##########################
####### OVERSEERR ########
##########################

/*

Separating the public requests site from the NUC's plex stack, so it can be isolated from the rest of the network

*/

let
  
  dataDir = "/var/lib/overseerr";
  docker = constants.docker;
in {
  
  imports = [
    ./container-base.nix
    ../services/rsync-backup.nix
  ];

  networking.firewall.allowedTCPPorts = [ constants.ports.overseerr ];
  users.users.overseerr = {
    uid = constants.users.multimedia;
    description = "Overseerr";
    isSystemUser = true;
    group = "overseerr";
    extraGroups = [ "wheel" ];
  };
  users.groups.overseerr.gid = constants.users.multimedia;

  services.rsyncBackup.overseerr = {
    enable = true;
    source = dataDir;
    schedule = "05:45";
  };

  virtualisation.oci-containers.containers.overseerr = {
    image = "ghcr.io/hotio/overseerr";
    ports = docker.ports.overseerr;
    environment = docker.environment;
    volumes = [
      "/var/lib/overseerr:/config"
    ];
  };
}
    
    