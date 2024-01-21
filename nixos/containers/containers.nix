{ config, pkgs, lib, ... }:

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

  # Use `sudo python -m serial.tools.miniterm` to find the dev path
  printerUsbPath = "/dev/ttyUSB0";

  ports = {
    octoprint = 5000;
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
    octoprint = ["${toString ports.octoprint}:${toString ports.octoprint}"];
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

 defaultEnvironment = {
    TZ = "America/Los_Angeles";
    UMASK_SET = "022";
    PUID = "950";
    PGID = "950";
 };
  
in {

  # Configure firewall to allow containers access to each other and external internet
  config.networking.firewall = {
    enable = true;
    # Containers don't get their ports exposed by default
    allowedTCPPorts = lib.attrValues ports;
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

    ###################
    #### Octoprint ####
    ###################

    octoprint = {
      image = "octoprint/octoprint";
      ports = dockerPorts.octoprint;
      environment = {
      	PUID = "950";
      	PGID = "950";
      	UMASK_SET = "022";
      	TZ = "America/Los_Angeles";
        ENABLE_MJPG_STREAMER = "true";
      };
      volumes = [
        "${arrConfigDir}/octoprint:/octoprint"
      ];
      extraOptions = [
        "--device=${printerUsbPath}"          
      ];
    };

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

  };
}
