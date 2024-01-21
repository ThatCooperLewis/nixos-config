{ config, pkgs, lib, ... }:

##########################
####### PLEX STACK #######
##########################

/*

Contrary to its name, this container set defines everything except Plex.
All surrounding microservices are set here, so Plex can run on a separate machine.

*/

let

  hostIP = "10.0.50.4";

  dataDir = "/mnt/plex-content";
  dataFallbackDir = "/mnt/plex-content-fallback";
  data4kDir = "/mnt/plex-content-4k";

  usenetDownloads = "/mnt/plex-downloads/data/usenet";
  usenet4kDownloads = "/mnt/plex-downloads/data-4k/usenet";

  tdarrTranscodeDir = "/mnt/nas-containers/tdarr/temp";
  
  arrConfigDir = "/home/cooper/Homelab/plex-stack";

  ports = {
    octoprint = 5000;
  	bazarr = 6767;
  	overseerr = 5055;
  	prowlarr = 9696;
  	radarr = 7878;
  	radarr4k = 7879;
  	requestrr = 4545;
  	sonarr = 8989;
  	sonarr4k = 8990;
  	tdarrServer = 8266; # 8265 for Web Portal, 8266 for Node/Server interop
  	tdarrWeb = 8265;
  };

  dockerPorts = {
    octoprint = ["${toString ports.octoprint}:${toString ports.octoprint}"];
  	bazarr = ["${toString ports.bazarr}:${toString ports.bazarr}"];
    overseerr = ["${toString ports.overseerr}:${toString ports.overseerr}"];
    prowlarr = ["${toString ports.prowlarr}:${toString ports.prowlarr}"];
    radarr = ["${toString ports.radarr}:${toString ports.radarr}"];
    radarr4k = ["${toString ports.radarr4k}:${toString ports.radarr}"];
    requestrr = ["${toString ports.requestrr}:${toString ports.requestrr}"];
    sonarr = ["${toString ports.sonarr}:${toString ports.sonarr}"];
    sonarr4k = ["${toString ports.sonarr4k}:${toString ports.sonarr}"];
    tdarr = [ 
      "${toString ports.tdarrWeb}:${toString ports.tdarrWeb}" 
      "${toString ports.tdarrServer}:${toString ports.tdarrServer}" 
    ];
  };

  defaultEnvironment = {
    TZ = "America/Los_Angeles";
    UMASK_SET = "022";
    PUID = "950";
    PGID = "950";
  };

  defaultOptions = [ "--network=plex-stack" ];

in {
  # Configure firewall to allow containers access to each other and external internet
  config.networking.firewall = {
    enable = true;
    # Containers don't get their ports exposed by default
    allowedTCPPorts = lib.attrValues ports;
    interfaces.docker1 = {
      # Allow ports to query each other
      allowedUDPPorts = [ 53 ];
    };
  };

  # Install docker
  config.virtualisation.oci-containers.backend = "docker";
  config.virtualisation.docker = {
  	enable = true;
  	enableOnBoot = true;
  	rootless = {
  	  enable = true;
  	  setSocketVariable = true;	
  	};
  };

  # From: https://madison-technologies.com/take-your-nixos-container-config-and-shove-it/
  # Create a shared network so containers can talk to each other
  config.systemd.services.create-plex-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ 
      "${backend}-sonarr.service"
      "${backend}-sonarr4k.service" 
      "${backend}-radarr.service" 
      "${backend}-radarr4k.service" 
      "${backend}-prowlarr.service" 
      "${backend}-overseerr.service"
      "${backend}-tdarr.service"      
      "${backend}-tdarrNode.service"
    ];
    script = ''${pkgs.docker}/bin/docker network create --driver bridge plex-stack || true'';
  };

  config.virtualisation.oci-containers.containers = {

  	sonarr = {
      image = "ghcr.io/hotio/sonarr";
      ports = dockerPorts.sonarr;
      environment = defaultEnvironment;
      volumes = [
	    "${arrConfigDir}/sonarr/config:/config"
 	    "${dataDir}/shows:/data/shows"
 	    "${dataFallbackDir}/shows:/data/shows-fallback"
 	    "${dataDir}/anime:/data/anime"
 	    "${usenetDownloads}:/data/usenet"
      ];
      extraOptions = defaultOptions;
    };

    sonarr4k = {
      image = "ghcr.io/hotio/sonarr";
      ports = dockerPorts.sonarr4k;
      environment = defaultEnvironment;
      volumes = [
	    "${arrConfigDir}/sonarr-4k/config:/config"
 	    "${data4kDir}/shows:/data-4k/shows"
 	    "${data4kDir}/anime:/data-4k/anime"
 	    "${usenet4kDownloads}:/data-4k/usenet"
      ];
      extraOptions = [ "--network=plex-stack" ];
    };

    radarr = {
      image = "ghcr.io/hotio/radarr";
      ports = dockerPorts.radarr;
      environment = defaultEnvironment;
      volumes = [
	    "${arrConfigDir}/radarr/config:/config"
 	    "${dataDir}/movies:/data/movies"
 	    "${dataFallbackDir}/movies:/data/movies-fallback"
 	    "${usenetDownloads}:/data/usenet"
      ];    	
      extraOptions = defaultOptions;
    };

    radarr4k = {
      image = "ghcr.io/hotio/radarr";
      ports = dockerPorts.radarr4k;
      environment = defaultEnvironment;
      volumes = [
	    "${arrConfigDir}/radarr-4k/config:/config"
 	    "${data4kDir}/movies:/data-4k/movies"
 	    "${usenet4kDownloads}:/data-4k/usenet"
      ];    	
      extraOptions = defaultOptions;
    };
 
    prowlarr = {
      image = "ghcr.io/hotio/prowlarr";
      ports = dockerPorts.prowlarr;
      environment = defaultEnvironment;
      volumes = [
        "${arrConfigDir}/prowlarr/config:/config"        
      ];
      extraOptions = defaultOptions;
    };

    overseerr = {
      image = "ghcr.io/hotio/overseerr";
      ports = dockerPorts.overseerr;
      environment = defaultEnvironment;
      volumes = [
        "${arrConfigDir}/overseerr/config:/config"
        "${dataDir}:/data"
        "${dataFallbackDir}:/data-fallback"
        "${data4kDir}:/data-4k"
      ];
      extraOptions = [ "--network=plex-stack" ];
    };

    requestrr = {
      image = "darkalfx/requestrr";
      ports = dockerPorts.requestrr;
      volumes = [
        "${arrConfigDir}/requestrr/config:/config"
      ];
    };

    bazarr = {
      image = "ghcr.io/hotio/bazarr";
      ports = dockerPorts.bazarr;
      environment = defaultEnvironment;
      volumes = [
        "${arrConfigDir}/bazarr/config:/config"
        "${arrConfigDir}/bazarr/logs:/logs"
        "${dataDir}/movies:/data/movies"
        "${dataFallbackDir}/shows:/data/shows-fallback"
        "${dataDir}/shows:/data/shows"
      ];
      extraOptions = defaultOptions;
    };

    tdarr = {
      image = "ghcr.io/haveagitgat/tdarr:latest";
      ports = dockerPorts.tdarr;
      environment = {
      	PUID = "950";
      	PGID = "950";
      	UMASK_SET = "022";
      	TZ = "America/Los_Angeles";
      	serverIP = hostIP;
      	serverPort = "${toString ports.tdarrServer}";
      	webUIPort = "${toString ports.tdarrWeb}";
      	internalNode = "false";
      	inContainer = "true";
      };
      volumes = [
        "${arrConfigDir}/tdarr/server:/app/server"
        "${arrConfigDir}/tdarr/configs:/app/configs"
        "${arrConfigDir}/tdarr/logs:/app/logs"
        "${data4kDir}:/data-4k"
        "${dataDir}:/data"
        "${tdarrTranscodeDir}:/temp"
      ];
      extraOptions = defaultOptions;
    };
 
    tdarrNode = {
      image = "ghcr.io/haveagitgat/tdarr_node:latest";
      environment = {
      	PUID = "950";
      	PGID = "950";
      	UMASK_SET = "022";
      	TZ = "America/Los_Angeles";
      	serverIP = hostIP;
      	serverPort = "${toString ports.tdarrServer}";
      	inContainer = "true";
      	max_old_space_size = "8152";
      	maxOldSpaceSize = "8152";
      	nodeName = "PrimaryNode";
      };
      volumes = [
        "${arrConfigDir}/tdarr/server:/app/server"
        "${arrConfigDir}/tdarr/configs:/app/configs"
        "${arrConfigDir}/tdarr/logs:/app/logs"
        "${data4kDir}:/data-4k"
        "${dataDir}:/data"
        "${tdarrTranscodeDir}:/temp"
      ];
      extraOptions = [
      	"--device=/dev/dri"
      	"--network=plex-stack"
      ];
    };

  };
}
