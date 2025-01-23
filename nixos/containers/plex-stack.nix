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

  systemd.services = {
    start-kometa = {
      description = "Start Kometa container";
      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker start kometa";
      };
    };
    stop-kometa = {
      description = "Stop Kometa container";
      serviceConfig = {
        ExecStart = "${pkgs.docker}/bin/docker stop kometa";
      };
    };
  };

  systemd.timers = {
    start-kometa-timer = {
      description = "Run Kometa container for 1 hour every 24 hours";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 00:00:00"; # Adjust to your desired start time
      };
    };
    stop-kometa-timer = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 01:00:00"; # 1 hour after start
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    constants.ports.bazarr
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
  systemd.services.create-plex-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ 
      "${backend}-bazarr.service"
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

  virtualisation.oci-containers.containers = {

    kometa = {
      autoStart = false;
      image = "kometateam/kometa";
      environment = {
        PUID = docker.users.multimedia;
        PGID = docker.users.multimedia;
        UMASK_SET = docker.environment.UMASK_SET;
        TZ = constants.localTimeZone;
        KOMETA_CONFIG = "/config/config.yml";
        KOMETA_RUN = "true";
      };
      volumes = [
        "${docker.dirs.arr}/kometa:/config"
      ];
      extraOptions = docker.plexArgs;
    };

    bazarr = {
      image = "ghcr.io/hotio/bazarr";
      ports = docker.ports.bazarr;
      environment = docker.environment;
      volumes = [
        "${docker.dirs.arr}/bazarr/config:/config"
        "${docker.dirs.arr}/bazarr/logs:/logs"
        "${docker.dirs.plexData}/movies:/data/movies"
        "${docker.dirs.plexData}/shows:/data/shows"
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
      image = "ghcr.io/hotio/radarr:release";
      ports = docker.ports.radarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/radarr/config:/config"
 	    "${docker.dirs.plexData}/movies:/data/movies"
 	    "${docker.dirs.usenetDownloads}:/data/usenet"
      ];    	
      extraOptions = docker.plexArgs;
    };

    radarr4k = {
      image = "ghcr.io/hotio/radarr:release";
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
      image = "ghcr.io/hotio/sonarr:release";
      ports = docker.ports.sonarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/sonarr/config:/config"
 	    "${docker.dirs.plexData}/shows:/data/shows"
 	    "${docker.dirs.plexData}/anime:/data/anime"
 	    "${docker.dirs.usenetDownloads}:/data/usenet"
      ];
      extraOptions = docker.plexArgs;
    };

    sonarr4k = {
      image = "ghcr.io/hotio/sonarr:release";
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

  	lidarr = {
      image = "ghcr.io/hotio/lidarr";
      ports = docker.ports.lidarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/lidarr/config:/config"
 	    "${docker.dirs.plexData}/music:/data/music"
 	    "${docker.dirs.usenetDownloads}:/data/usenet"
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
