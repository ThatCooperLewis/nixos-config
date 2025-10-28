{ config, pkgs, lib, constants, ... }:

#########################
####### ARR STACK #######
#########################

/*

All surrounding Plex microservices are set here.

*/

let
  
  docker = constants.docker;

in {

  imports = [
    ./container-base.nix
    ../services/rsync-backup.nix
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

  services.rsyncBackup.arrStack = {
    enable = true;
    source = docker.dirs.arr;
    schedule = "06:30";
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
        "${docker.dirs.plexDataUnified}:/plex-content"
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
      "${docker.dirs.plexDataUnified}:/plex-content"
      ];    	
      extraOptions = docker.plexArgs;
    };

    radarr4k = {
      image = "ghcr.io/hotio/radarr:release";
      ports = docker.ports.radarr4k;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/radarr-4k/config:/config"
      "${docker.dirs.plexDataUnified}:/plex-content"
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
      "${docker.dirs.plexDataUnified}:/plex-content"
      ];
      extraOptions = docker.plexArgs;
    };

    sonarr4k = {
      image = "ghcr.io/hotio/sonarr:release";
      ports = docker.ports.sonarr4k;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/sonarr-4k/config:/config"
      "${docker.dirs.plexDataUnified}:/plex-content"
      ];
      extraOptions = docker.plexArgs;
    };

  	lidarr = {
      image = "ghcr.io/hotio/lidarr";
      ports = docker.ports.lidarr;
      environment = docker.environment;
      volumes = [
	    "${docker.dirs.arr}/lidarr/config:/config"
      "${docker.dirs.plexDataUnified}:/plex-content"
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
        "${docker.dirs.plexDataUnified}:/plex-content"
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
        "${docker.dirs.plexDataUnified}:/plex-content"
      ];
      extraOptions = [
      	"--device=/dev/dri"
      	"--network=plex-stack"
      ];
    };

  };
}
