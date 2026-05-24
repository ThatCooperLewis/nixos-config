{ config, pkgs, lib, constants, ... }:

let
  docker = constants.docker;
in {

  imports = [
    ./container-base.nix
  ];

  users.users.multimedia = {
    uid = 950;
    group = "multimedia";
  	description = "Plex Stack";
  	extraGroups = [ "docker" "networkmanager" "wheel" ];
  };
  users.groups.multimedia.gid = 950;

  virtualisation.oci-containers.containers.tdarrNode = {
    image = "ghcr.io/haveagitgat/tdarr_node:2.61.01";
    environment = {
    	PUID = docker.users.multimedia;
    	PGID = docker.users.multimedia;
    	UMASK_SET = docker.environment.UMASK_SET;
    	TZ = constants.localTimeZone;
    	serverIP = docker.tdarrServerIP;
    	serverPort = "${toString constants.ports.tdarrServer}";
    	inContainer = "true";
    	max_old_space_size = "8152";
    	maxOldSpaceSize = "8152";
    	nodeName = "IsolatedNode";
    };
    volumes = [
      "${docker.dirs.arr}/tdarr/server:/app/server"
      "${docker.dirs.arr}/tdarr/configs:/app/configs"
      "${docker.dirs.arr}/tdarr/logs:/app/logs"
      "${docker.dirs.plexData}:/plex-content"
    ];
    extraOptions = [];
  };
}
