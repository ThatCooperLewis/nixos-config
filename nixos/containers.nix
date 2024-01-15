{ config, pkgs, ... }:

let

  hostIP = "10.0.50.1";

  dataDir = "/mnt/plex-content";
  dataFallbackDir = "/mnt/plex-content-fallback";
  data4kDir = "/mnt/plex-content-4k";

  usenetDownloads = "/mnt/plex-downloads/data/usenet";
  usenet4kDownloads = "/mnt/plex-downloads/data-4k/usenet";

  tdarrTranscodeDir = "/mnt/nas-containers/tdarr/temp";
  
  arrConfigDir = "/mnt/config-array";
  plexConfigDir = "/mnt/config-array/plex/config";
  plexTranscodeDir = "/mnt/config-array/plex/transcode";

  # TODO: Split this into separate option
  # containerGpus = "all";
  # When using the second GPU, but the primary is still nix-visible
  containerGpus = "\"device=1\"";

  ports = {
  	bazarr = 6767;
  	nzbget = 6789; # 6789 for HTTP, 6791 for HTTPS
  	nzbgetSSL = 6791;
  	overseerr = 5055;
  	plex = 32400;
  	plexUDP = 32469;
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
  	bazarr = ["${toString ports.bazarr}:${toString ports.bazarr}"];
    nzbget = [
      "${toString ports.nzbget}:${toString ports.nzbget}"
      "${toString ports.nzbgetSSL}:${toString ports.nzbgetSSL}"
    ];
    overseerr = ["${toString ports.overseerr}:${toString ports.overseerr}"];
    plex = [
      "${toString ports.plex}:${toString ports.plex}"
      "${toString ports.plexUDP}:${toString ports.plexUDP}"
    ];
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
  
in {

  # Configure firewall to allow containers access to each other and external internet
  config.networking.firewall = {
    enable = true;
    # Containers don't get their ports exposed by default
    allowedTCPPorts = [ ports.bazarr ports.nzbget ports.nzbgetSSL ports.overseerr 
      					ports.plex ports.prowlarr ports.radarr ports.radarr4k ports.requestrr 
      					ports.sonarr ports.sonarr4k ports.tdarrServer ports.tdarrWeb 
    				];
    allowedUDPPorts = [ ports.plexUDP ];
    interfaces.docker1 = {
      # Allow ports to query each other
      allowedUDPPorts = [ 53 ];
    };
  };

  # Install docker, make it compatible with Nvidia GPUs
  config.virtualisation.docker = {
  	enable = true;
  	enableNvidia = true;
  	enableOnBoot = true;
  	rootless = {
  	  enable = true;
  	  setSocketVariable = true;	
  	};
  };

  # libnvidia-container does not support cgroups v2 (prior to 1.8.0)
  # https://github.com/NVIDIA/nvidia-docker/issues/1447
  config.systemd.enableUnifiedCgroupHierarchy = false;

  # OCI Backend is Podman by default
  # It does not support Nvidia GPUs with Plex 
  config.virtualisation.oci-containers.backend = "docker";

  # From: https://madison-technologies.com/take-your-nixos-container-config-and-shove-it/
  # Create a shared network so containers can talk to each other
  config.systemd.services.create-plex-network = with config.virtualisation.oci-containers; {
    serviceConfig.Type = "oneshot";
    wantedBy = [ 
      "${backend}-plex.service" 
      "${backend}-sonarr.service"
      "${backend}-sonarr4k.service" 
      "${backend}-radarr.service" 
      "${backend}-radarr4k.service" 
      "${backend}-prowlarr.service" 
      "${backend}-nzbget.service" 
      "${backend}-overseerr.service" 
    ];
    script = ''${pkgs.docker}/bin/docker network create --driver bridge plex-stack || true'';
  };

  config.virtualisation.oci-containers.containers = {

    ###########################
    #### Plex Media Server ####
    ###########################

    plex = {
      image = "plexinc/pms-docker:plexpass";
      ports = dockerPorts.plex;
      environment = {
      	PLEX_UID = "950";
      	PLEX_GID = "950";
      	PLEX_CLAIM = "claim-s8wyAfhFGKpdEU2JmusY";
      	ADVERTISE_IP = "http://${hostIP}:${toString ports.plex}";
      	NVIDIA_VISIBLE_DEVICES = "1";
      	NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
      };
      volumes = [
        "${plexConfigDir}:/config"
        "${plexTranscodeDir}:/transcode"
        "${dataDir}:/data"
        "${dataFallbackDir}:/data-fallback"
        "${plexTranscodeDir}:/data-4k"
      ];
      extraOptions = [
      	"--runtime=nvidia"
      	"--gpus=${containerGpus}"
      	"--network=plex-stack"
      ];
    };

    #########################
    #### Sonarr & Radarr ####
    #########################

    sonarr = {
      image = "ghcr.io/hotio/sonarr";
      ports = dockerPorts.sonarr;
      environmentFiles = [ ./plexDefault.env ];
      volumes = [
	    "${arrConfigDir}/sonarr/config:/config"
 	    "${dataDir}/shows:/data/shows"
 	    "${dataFallbackDir}/shows:/data/shows-fallback"
 	    "${dataDir}/anime:/data/anime"
 	    "${usenetDownloads}:/data/usenet"
      ];
      extraOptions = [ "--network=plex-stack" ];
    };

    sonarr4k = {
      image = "ghcr.io/hotio/sonarr";
      ports = dockerPorts.sonarr4k;
      environmentFiles = [ ./plexDefault.env ];
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
      environmentFiles = [ ./plexDefault.env ];
      volumes = [
	    "${arrConfigDir}/radarr/config:/config"
 	    "${dataDir}/movies:/data/movies"
 	    "${dataFallbackDir}/movies:/data/movies-fallback"
 	    "${usenetDownloads}:/data/usenet"
      ];    	
      extraOptions = [ "--network=plex-stack" ];
    };

    radarr4k = {
      image = "ghcr.io/hotio/radarr";
      ports = dockerPorts.radarr4k;
      environmentFiles = [ ./plexDefault.env ];
      volumes = [
	    "${arrConfigDir}/radarr-4k/config:/config"
 	    "${data4kDir}/movies:/data-4k/movies"
 	    "${usenet4kDownloads}:/data-4k/usenet"
      ];    	
      extraOptions = [ "--network=plex-stack" ];
    };

    ###########################
    #### Prowlarr & NZBGet ####
    ###########################

    prowlarr = {
      image = "ghcr.io/hotio/prowlarr";
      ports = dockerPorts.prowlarr;
      environmentFiles = [ ./plexDefault.env ];
      volumes = [
        "${arrConfigDir}/prowlarr/config:/config"        
      ];
      extraOptions = [ "--network=plex-stack" ];
    };

    nzbget = {
      image = "lscr.io/linuxserver/nzbget:latest";
      ports = dockerPorts.nzbget;
      environmentFiles = [ ./plexDefault.env ];
      volumes = [
        "${arrConfigDir}/nzbget/config:/config"
        "${usenetDownloads}:/data/usenet"
        "${usenet4kDownloads}:/data-4k/usenet"
        # Path to SSL certs used to be provided, but they're dead now       
      ];
      extraOptions = [ "--network=plex-stack" ];
    };

    ###############################
    #### Overseerr & Requestrr ####
    ###############################

    overseerr = {
      image = "ghcr.io/hotio/overseerr";
      ports = dockerPorts.overseerr;
      environmentFiles = [ ./plexDefault.env ];
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

    ########################
    #### Tdarr & Bazarr ####
    ########################

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
      	nodeName = "MyInternalNode";
      	NVIDIA_VISIBLE_DEVICES = "1";
      	NVIDIA_DRIVER_CAPABILITIES = "all";
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
      	"--runtime=nvidia"
      	"--gpus=${containerGpus}"
      	"--network=plex-stack"
      ];
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
      	NVIDIA_VISIBLE_DEVICES = "1";
      	NVIDIA_DRIVER_CAPABILITIES = "all";
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
      	"--runtime=nvidia"
      	"--gpus=${containerGpus}"
      	"--network=plex-stack"
      ];
    };

    bazarr = {
      image = "ghcr.io/hotio/bazarr";
      ports = dockerPorts.bazarr;
      environmentFiles = [ ./plexDefault.env ];
      environment = {
        UMASK_SET = "022";
      };
      volumes = [
        "${arrConfigDir}/bazarr/config:/config"
        "${arrConfigDir}/bazarr/logs:/logs"
        "${dataDir}/movies:/data/movies"
        "${dataFallbackDir}/shows:/data/shows-fallback"
        "${dataDir}/shows:/data/shows"
      ];
      extraOptions = [ "--network=plex-stack" ];
    };
  };
}
