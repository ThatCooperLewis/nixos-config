{ config, pkgs, lib, constants, ... }:

##########################
####### PLEX STACK #######
##########################

/*

Contrary to its name, this container set defines everything except Plex.
All surrounding microservices are set here, so Plex can run on a separate machine.

*/

let
  
  docker = constants.docker;

in {

  config.networking.firewall.allowedTCPPorts = [
    constants.ports.bazarr
    constants.ports.overseerr
    constants.ports.prowlarr
    constants.ports.radarr
    constants.ports.radarr4k
    constants.ports.requestrr
    constants.ports.sonarr
    constants.ports.sonarr4k
    constants.ports.tautulli
    constants.ports.tdarrServer
    constants.ports.tdarrWeb
  ];

  # From: https://madison-technologies.com/take-your-nixos-container-config-and-shove-it/
  # Create a shared network so containers can talk to each other
  config.systemd.services.create-plex-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ 
      "${backend}-bazarr.service"
      "${backend}-overseerr.service"
      "${backend}-prowlarr.service" 
      "${backend}-radarr.service" 
      "${backend}-radarr4k.service" 
      "${backend}-requestrr.service" 
      "${backend}-sonarr.service"
      "${backend}-sonarr4k.service" 
      "${backend}-tautulli.service"
      "${backend}-tdarr.service"      
      "${backend}-tdarrNode.service"
    ];
    script = ''${pkgs.docker}/bin/docker network create --driver bridge plex-stack || true'';
  };

  config.virtualisation.oci-containers.containers = {

    bazarr = {
      image = "ghcr.io/hotio/bazarr";
      ports = docker.ports.bazarr;
      environment = docker.environment;
      volumes = [
        "${docker.dirs.arr}/bazarr/config:/config"
        "${docker.dirs.arr}/bazarr/logs:/logs"
        "${docker.dirs.plexData}/movies:/data/movies"
        "${docker.dirs.plexDataFallback}/shows:/data/shows-fallback"
        "${docker.dirs.plexData}/shows:/data/shows"
      ];
      extraOptions = docker.plexArgs;
    };

    overseerr = {
      image = "ghcr.io/hotio/overseerr";
      ports = docker.ports.overseerr;
      environment = docker.environment;
      volumes = [
        "${docker.dirs.arr}/overseerr/config:/config"
        "${docker.dirs.plexData}:/data"
        "${docker.dirs.plexDataFallback}:/data-fallback"
        "${docker.dirs.plexData4k}:/data-4k"
      ];
      extraOptions = docker.plexArgs;
    };
 
    prowlarr = {
      image = "ghcr.io/hotio/prowlarr";
      ports = docker.ports.prowlarr;
      environment = docker.environment;
      volumes = [
        "${docker.dirs.arr}/prowlarr/config:/config"        
      ];
      extraOptions = docker.plexArgs;
    };

    radarr = {
      image = "ghcr.io/hotio/radarr";
      ports = docker.ports.radarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/radarr/config:/config"
 	    "${docker.dirs.plexData}/movies:/data/movies"
 	    "${docker.dirs.plexDataFallback}/movies:/data/movies-fallback"
 	    "${docker.dirs.usenetDownloads}:/data/usenet"
      ];    	
      extraOptions = docker.plexArgs;
    };

    radarr4k = {
      image = "ghcr.io/hotio/radarr";
      ports = docker.ports.radarr4k;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/radarr-4k/config:/config"
 	    "${docker.dirs.plexData4k}/movies:/data-4k/movies"
 	    "${docker.dirs.usenet4kDownloads}:/data-4k/usenet"
      ];    	
      extraOptions = docker.plexArgs;
    };

    requestrr = {
      image = "darkalfx/requestrr";
      ports = docker.ports.requestrr;
      volumes = [
        "${docker.dirs.arr}/requestrr/config:/config"
      ];
    };

  	sonarr = {
      image = "ghcr.io/hotio/sonarr";
      ports = docker.ports.sonarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/sonarr/config:/config"
 	    "${docker.dirs.plexData}/shows:/data/shows"
 	    "${docker.dirs.plexDataFallback}/shows:/data/shows-fallback"
 	    "${docker.dirs.plexDataFallback}/anime:/data/anime"
 	    "${docker.dirs.usenetDownloads}:/data/usenet"
      ];
      extraOptions = docker.plexArgs;
    };

    sonarr4k = {
      image = "ghcr.io/hotio/sonarr";
      ports = docker.ports.sonarr4k;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/sonarr-4k/config:/config"
 	    "${docker.dirs.plexData4k}/shows:/data-4k/shows"
 	    "${docker.dirs.plexData4k}/anime:/data-4k/anime"
 	    "${docker.dirs.usenet4kDownloads}:/data-4k/usenet"
      ];
      extraOptions = docker.plexArgs;
    };

    tautulli = {
      image = "ghcr.io/tautulli/tautulli";
      ports = docker.ports.tautulli;
      environment = docker.environment;
      volumes = [ 
        "${docker.dirs.arr}/tautulli:/config"
      ];
    };

    tdarr = {
      image = "ghcr.io/haveagitgat/tdarr:latest";
      ports = docker.ports.tdarr;
      environment = {
      	PUID = docker.users.multimedia;
      	PGID = docker.users.multimedia;
      	UMASK_SET = docker.environment.UMASK_SET;
      	TZ = constants.localTimeZone;
      	serverIP = docker.tdarrServerIP;
      	serverPort = "${toString constants.ports.tdarrServer}";
      	webUIPort = "${toString constants.ports.tdarrWeb}";
      	internalNode = "false";
      	inContainer = "true";
      };
      volumes = [
        "${docker.dirs.arr}/tdarr/server:/app/server"
        "${docker.dirs.arr}/tdarr/configs:/app/configs"
        "${docker.dirs.arr}/tdarr/logs:/app/logs"
        "${docker.dirs.plexData4k}:/data-4k"
        "${docker.dirs.plexData}:/data"
        "${docker.dirs.tdarrTranscode}:/temp"
      ];
      extraOptions = docker.plexArgs;
    };
 
    tdarrNode = {
      image = "ghcr.io/haveagitgat/tdarr_node:latest";
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
      	nodeName = "PrimaryNode";
      };
      volumes = [
        "${docker.dirs.arr}/tdarr/server:/app/server"
        "${docker.dirs.arr}/tdarr/configs:/app/configs"
        "${docker.dirs.arr}/tdarr/logs:/app/logs"
        "${docker.dirs.plexData4k}:/data-4k"
        "${docker.dirs.plexData}:/data"
        "${docker.dirs.tdarrTranscode}:/temp"
      ];
      extraOptions = [
      	"--device=/dev/dri"
      	"--network=plex-stack"
      ];
    };
  };
}
